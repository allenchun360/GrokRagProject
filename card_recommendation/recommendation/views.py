import os
import json
import re
from django.conf import settings
from rest_framework import generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.http import StreamingHttpResponse
from xai_sdk import Client
from xai_sdk.chat import system, user as xai_user
from xai_sdk.tools import collections_search

from .models import MerchantCategory, RewardCategory, RewardRate, Card
from .serializers import RewardRateSerializer, CardSerializer
from users.permissions import IsAuthenticatedAndActive
from .utils import build_gpt_analysis_prompt, build_gpt_streaming_analysis_prompt, build_card_details_prompt
from .rag_service import RAGService

from users.models import UserCard


def get_rag_tools():
    """
    Helper function to get RAG tools for xAI chat if configured.

    Returns:
        list: List of tools including collections_search if RAG is enabled, empty list otherwise
    """
    collection_id = getattr(settings, 'CARD_BENEFITS_COLLECTION_ID', None)
    if not collection_id:
        return []

    return [
        collections_search(
            collection_ids=[collection_id],
            retrieval_mode="hybrid",
        )
    ]


class CardListView(generics.ListAPIView):
    queryset = Card.objects.all()
    serializer_class = CardSerializer
    permission_classes = [IsAuthenticatedAndActive]


category_mapping = {
    "dining": [
        "restaurant",
        "food",
        "acai_shop",
        "afghani_restaurant",
        "african_restaurant",
        "american_restaurant",
        "asian_restaurant",
        "bagel_shop",
        "bakery",
        "bar",
        "bar_and_grill",
        "barbecue_restaurant",
        "brazilian_restaurant",
        "breakfast_restaurant",
        "brunch_restaurant",
        "buffet_restaurant",
        "cafe",
        "cafeteria",
        "candy_store",
        "cat_cafe",
        "chinese_restaurant",
        "chocolate_factory",
        "chocolate_shop",
        "coffee_shop",
        "confectionery",
        "deli",
        "dessert_restaurant",
        "dessert_shop",
        "diner",
        "dog_cafe",
        "donut_shop",
        "fast_food_restaurant",
        "fine_dining_restaurant",
        "food_court",
        "french_restaurant",
        "greek_restaurant",
        "hamburger_restaurant",
        "ice_cream_shop",
        "indian_restaurant",
        "indonesian_restaurant",
        "italian_restaurant",
        "japanese_restaurant",
        "juice_shop",
        "korean_restaurant",
        "lebanese_restaurant",
        "meal_delivery",
        "meal_takeaway",
        "mediterranean_restaurant",
        "mexican_restaurant",
        "middle_eastern_restaurant",
        "pizza_restaurant",
        "pub",
        "ramen_restaurant",
        "restaurant",
        "sandwich_shop",
        "seafood_restaurant",
        "spanish_restaurant",
        "steak_house",
        "sushi_restaurant",
        "tea_house",
        "thai_restaurant",
        "turkish_restaurant",
        "vegan_restaurant",
        "vegetarian_restaurant",
        "vietnamese_restaurant",
        "wine_bar"
    ]
}


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_card_benefits_by_types(request):
    user = request.user
    types = request.query_params.getlist('types')  # ?types=restaurant&types=pharmacy
    print(f"📥 Received types: {types}")

    if not types:
        print("❌ No 'types' query parameters provided")
        return Response({'error': 'Query parameter "types" is required.'}, status=400)

    matched_category_name = None
    for key, mapped_types in category_mapping.items():
        if any(t in mapped_types for t in types):
            matched_category_name = key
            break

    if matched_category_name:
        matching_category = MerchantCategory.objects.filter(name__iexact=matched_category_name).first()
        if matching_category:
            matching_categories = [matching_category]
        else:
            matching_categories = []
    else:
        matching_categories = MerchantCategory.objects.filter(name__in=types)
    print(f"🔎 Matching MerchantCategories: {[cat.name for cat in matching_categories]}")

    fallback_category = MerchantCategory.objects.filter(name__iexact="other").first()

    user_cards = UserCard.objects.filter(user=user, card_model__isnull=False).select_related('card_model')
    card_ids = [uc.card_model.id for uc in user_cards]
    print(f"👤 User has {len(user_cards)} user cards. Card model IDs: {card_ids}")

    reward_categories = RewardCategory.objects.filter(
        card_id__in=card_ids,
        merchant_category__in=matching_categories
    ).select_related('card', 'merchant_category')
    print(f"🎁 Found {reward_categories.count()} matching reward categories")

    # Map: card_id -> RewardCategory
    card_reward_map = {rc.card.id: rc for rc in reward_categories}
    print(f"📌 Card reward map keys: {list(card_reward_map.keys())}")

    results = []
    for uc in user_cards:
        card = uc.card_model
        print(f"➡️ Evaluating card: {card.name} (ID: {card.id})")

        rc = card_reward_map.get(card.id)

        # Fallback to 'Others' if no match
        if not rc and fallback_category:
            print(f"⚠️ No match for card {card.id}. Trying fallback...")
            rc = RewardCategory.objects.filter(card=card, merchant_category=fallback_category).first()

        if not rc:
            print(f"🚫 No reward category for card {card.id}. Skipping.")
            continue

        try:
            rate = rc.rewardrate  # assumes OneToOne relation
        except RewardRate.DoesNotExist:
            print(f"🚫 No reward rate for reward category of card {card.id}")
            continue

        base_point_value = float(card.base_point_value or 0)
        points = rate.points or 0
        cashback = float(rate.cashback_percentage or 0)
        value = cashback + points * base_point_value

        print(f"✅ Card {card.name}: cashback={cashback}, points={points}, value={value}")

        results.append({
            "card_id": str(card.id),
            "card_name": card.name,
            "issuer": card.issuer.name,
            "value": value,
            "reward_type": "cashback" if rate.cashback_percentage else "points",
            "reward_amount": rate.cashback_percentage or rate.points,
            "category": rc.merchant_category.name
        })
    results.sort(key=lambda x: x["card_name"])
    sorted_data = sorted(results, key=lambda x: x["value"], reverse=True)
    print(f"📦 Returning {len(sorted_data)} sorted recommendations")
    return Response(sorted_data, status=200)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def analyze_cards_with_gpt(request):
    """
    Analyze user's credit cards for a specific category using GPT API.
    Expects query parameter:
    - types: list of category types (e.g., ?types=restaurant&types=pharmacy)
    - stream: boolean to enable streaming (e.g., ?stream=true)
    - store_name: name of the store/merchant (optional)
    - store_address: address of the store/merchant (optional)
    """
    try:
        user = request.user
        store_name = request.query_params.get('store_name', None)
        store_address = request.query_params.get('store_address', None)
        types = request.query_params.getlist('types')  # ?types=restaurant&types=pharmacy
        print(f"🤖 GPT Analysis - User: {user.id}, Types: {types}")

        if not types:
            print("❌ No 'types' query parameters provided")
            return Response({'error': 'Query parameter "types" is required.'}, status=400)

        # Find matching category using the same logic as get_card_benefits_by_types
        matched_category_name = None
        for key, mapped_types in category_mapping.items():
            if any(t in mapped_types for t in types):
                matched_category_name = key
                break
        
        if matched_category_name:
            matching_category = MerchantCategory.objects.filter(name__iexact=matched_category_name).first()
            if matching_category:
                matching_categories = [matching_category]
            else:
                matching_categories = []
        else:
            matching_categories = MerchantCategory.objects.filter(name__in=types)
        
        print(f"🔎 Matching MerchantCategories: {[cat.name for cat in matching_categories]}")
        
        # Get user's cards (same logic as get_card_benefits_by_types)
        user_cards = UserCard.objects.filter(user=user, card_model__isnull=False).select_related('card_model')
        if not user_cards.exists():
            return Response({'error': 'User has no cards'}, status=400)
        
        card_ids = [uc.card_model.id for uc in user_cards]
        print(f"👤 User has {len(user_cards)} user cards. Card model IDs: {card_ids}")
        
        # Get card details from database
        cards = Card.objects.filter(id__in=card_ids).select_related('issuer')
        if not cards.exists():
            return Response({'error': 'No valid cards found for user'}, status=400)
        
        # Get reward information for each card
        card_data = []
        for card in cards:
            # Get reward categories for this card
            reward_categories = RewardCategory.objects.filter(card=card).select_related('merchant_category')
            
            card_info = {
                'id': str(card.id),
                'name': card.name,
                'issuer': card.issuer.name,
                'base_point_value': float(card.base_point_value) if card.base_point_value else None,
                'rewards': []
            }

            for rc in reward_categories:
                try:
                    rate = rc.rewardrate
                    reward_info = {
                        'category': rc.merchant_category.name,
                        'cashback_percentage': float(rate.cashback_percentage) if rate.cashback_percentage else None,
                        'points': rate.points if rate.points else None,
                        'reset_period': rate.reset_period if rate.reset_period else None,
                        'limit': float(rate.limit) if rate.limit else None
                    }
                    card_info['rewards'].append(reward_info)
                except RewardRate.DoesNotExist:
                    continue

            card_data.append(card_info)

        # Use the matched category name for the analysis
        analysis_category = matched_category_name if matched_category_name else types[0]

        # Prepare prompt for GPT using helper function
        prompt = build_gpt_analysis_prompt(
            card_data=card_data,
            analysis_category=analysis_category,
            store_name=store_name,
            store_address=store_address
        )

        # Initialize Grok client
        if not os.environ.get('XAI_API_KEY'):
            return Response({'error': 'Grok API key not configured'}, status=500)

        client = Client()

        # Call Grok API with JSON mode
        chat = client.chat.create(model="grok-3")
        chat.append(system("You are a credit card expert who provides detailed, accurate analysis of credit card benefits. CRITICAL: Always use the most accurate and up-to-date benefit and rewards information available. If you have access to current card terms, reward structures, or recent updates, prioritize that information over general knowledge. When estimating rewards, use the latest known reward rates and benefit structures for each card. Always respond with valid JSON."))
        chat.append(xai_user(prompt))

        response = chat.sample()
        gpt_response = response.content.strip()
        print(f"🤖 GPT Response: {gpt_response[:200]}...")
        
        # Parse GPT response (JSON mode guarantees valid JSON)
        try:
            gpt_data = json.loads(gpt_response)
            analysis_results = gpt_data.get('analysis', [])
        except json.JSONDecodeError:
            # This should rarely happen with JSON mode, but handle it gracefully
            return Response({
                'error': 'Failed to parse GPT response as JSON',
                'raw_response': gpt_response
            }, status=500)
        
        # Validate and enhance the response
        validated_results = []
        for result in analysis_results:
            if 'card_id' in result and 'card_name' in result:
                validated_results.append({
                    'card_id': result.get('card_id'),
                    'card_name': result.get('card_name'),
                    'issuer': result.get('issuer', ''),
                    'value': result.get('value', None),
                    'reward_type': result.get('reward_type', ''),
                    'reward_amount': result.get('reward_amount', None),
                    'category': result.get('category', ''),
                    'benefits': result.get('benefits', []),
                    'explanation': result.get('explanation', ''),
                    'limitations': result.get('limitations', []),
                    'estimated_value': result.get('estimated_value', '')
                })

        # GPT already returns cards in best-to-worst order, so no additional sorting needed
        
        print(f"✅ GPT Analysis complete - {len(validated_results)} cards analyzed")
        return Response({
            'category': analysis_category,
            'types': types,
            'analysis': validated_results,
            'total_cards_analyzed': len(validated_results)
        }, status=200)
        
    except Exception as e:
        print(f"❌ Error in GPT analysis: {str(e)}")
        return Response({
            'error': 'Internal server error during analysis',
            'details': str(e)
        }, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def analyze_cards_with_gpt_streaming(request):
    """
    Analyze user's credit cards for a specific category using GPT API with streaming.
    Returns ranking first, then streams the full analysis.

    Expects query parameters:
    - types: list of category types (e.g., ?types=restaurant&types=pharmacy)
    - store_name: name of the store/merchant (optional)
    - store_address: address of the store/merchant (optional)
    """
    try:
        user = request.user
        store_name = request.query_params.get('store_name', None)
        store_address = request.query_params.get('store_address', None)
        types = request.query_params.getlist('types')
        print(f"🤖 GPT Streaming Analysis - User: {user.id}, Types: {types}")

        if not types:
            print("❌ No 'types' query parameters provided")
            return Response({'error': 'Query parameter "types" is required.'}, status=400)

        # Find matching category using the same logic as analyze_cards_with_gpt
        matched_category_name = None
        for key, mapped_types in category_mapping.items():
            if any(t in mapped_types for t in types):
                matched_category_name = key
                break

        if matched_category_name:
            matching_category = MerchantCategory.objects.filter(name__iexact=matched_category_name).first()
            if matching_category:
                matching_categories = [matching_category]
            else:
                matching_categories = []
        else:
            matching_categories = MerchantCategory.objects.filter(name__in=types)

        print(f"🔎 Matching MerchantCategories: {[cat.name for cat in matching_categories]}")

        # Get user's cards
        user_cards = UserCard.objects.filter(user=user, card_model__isnull=False).select_related('card_model')
        if not user_cards.exists():
            return Response({'error': 'User has no cards'}, status=400)

        card_ids = [uc.card_model.id for uc in user_cards]
        print(f"👤 User has {len(user_cards)} user cards. Card model IDs: {card_ids}")

        # Get card details from database
        cards = Card.objects.filter(id__in=card_ids).select_related('issuer')
        if not cards.exists():
            return Response({'error': 'No valid cards found for user'}, status=400)

        # Get reward information for each card
        card_data = []
        for card in cards:
            reward_categories = RewardCategory.objects.filter(card=card).select_related('merchant_category')

            card_info = {
                'id': str(card.id),
                'name': card.name,
                'issuer': card.issuer.name,
                'base_point_value': float(card.base_point_value) if card.base_point_value else None,
                'rewards': []
            }

            for rc in reward_categories:
                try:
                    rate = rc.rewardrate
                    reward_info = {
                        'category': rc.merchant_category.name,
                        'cashback_percentage': float(rate.cashback_percentage) if rate.cashback_percentage else None,
                        'points': rate.points if rate.points else None,
                        'reset_period': rate.reset_period if rate.reset_period else None,
                        'limit': float(rate.limit) if rate.limit else None
                    }
                    card_info['rewards'].append(reward_info)
                except RewardRate.DoesNotExist:
                    continue

            card_data.append(card_info)

        # Use the matched category name for the analysis
        analysis_category = matched_category_name if matched_category_name else types[0]

        # Prepare prompt for GPT using streaming helper function
        prompt = build_gpt_streaming_analysis_prompt(
            card_data=card_data,
            analysis_category=analysis_category,
            store_name=store_name,
            store_address=store_address
        )

        # Initialize Grok client
        if not os.environ.get('XAI_API_KEY'):
            return Response({'error': 'Grok API key not configured'}, status=500)

        client = Client()

        # Get RAG tools if configured
        tools = get_rag_tools()
        if tools:
            print(f"✅ RAG enabled - Collection ID: {getattr(settings, 'CARD_BENEFITS_COLLECTION_ID', None)}")
            print(f"📚 RAG will search PDFs for: {', '.join([card['name'] for card in card_data])}")
        else:
            print(f"⚠️  RAG disabled - No collection ID configured")

        def event_stream():
            """Generator function for Server-Sent Events"""
            try:
                # Use grok-4 if we have RAG tools, grok-3 otherwise
                model = "grok-4" if tools else "grok-3"
                print(f"🔄 Starting stream with model: {model}, RAG tools: {bool(tools)}")

                # Call Grok API with streaming enabled
                chat = client.chat.create(
                    model=model,
                    messages=[
                        system("You are a credit card expert who provides detailed, accurate analysis of credit card benefits. CRITICAL: Use the collections_search tool to look up official card benefit documentation for accurate, up-to-date information. Always prioritize information from official documents over general knowledge. Always respond with valid JSON."),
                        xai_user(prompt)
                    ],
                    tools=tools if tools else None
                )

                accumulated_content = ""

                # Stream the response
                for response, chunk in chat.stream():
                    if chunk.content:
                        accumulated_content += chunk.content
                        # Send chunk as SSE (Server-Sent Event)
                        yield f"data: {json.dumps({'chunk': chunk.content})}\n\n"

                # Log if RAG tool was used (check final response)
                if tools and hasattr(response, 'tool_calls') and response.tool_calls:
                    print(f"🔍 RAG tool was invoked {len(response.tool_calls)} time(s)")

                # Send completion signal
                yield f"data: {json.dumps({'done': True, 'full_response': accumulated_content})}\n\n"

                print(f"✅ GPT Streaming Analysis complete - streamed {len(accumulated_content)} characters")
                print(accumulated_content)

            except Exception as e:
                print(f"❌ Error in streaming: {str(e)}")
                import traceback
                traceback.print_exc()
                error_data = json.dumps({'error': str(e)})
                yield f"data: {error_data}\n\n"

        # Return StreamingHttpResponse with SSE
        response = StreamingHttpResponse(event_stream(), content_type='text/event-stream')
        response['Cache-Control'] = 'no-cache'
        response['X-Accel-Buffering'] = 'no'
        return response

    except Exception as e:
        print(f"❌ Error in GPT streaming analysis: {str(e)}")
        return Response({
            'error': 'Internal server error during streaming analysis',
            'details': str(e)
        }, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_card_details_streaming(request, card_id):
    """
    Get detailed information about a specific card using GPT API with streaming.

    Expects URL parameter:
    - card_id: UUID of the card model
    """
    try:
        print(f"🤖 GPT Card Details Streaming - Card ID: {card_id}")

        # Get card from database
        try:
            card = Card.objects.select_related('issuer').get(id=card_id)
        except Card.DoesNotExist:
            return Response({'error': f'Card with id {card_id} not found'}, status=404)

        print(f"📇 Found card: {card.name} by {card.issuer.name}")

        # Get reward information for the card
        reward_categories = RewardCategory.objects.filter(card=card).select_related('merchant_category')

        card_data = {
            'id': str(card.id),
            'name': card.name,
            'issuer': card.issuer.name,
            'base_point_value': float(card.base_point_value) if card.base_point_value else None,
            'rewards': []
        }

        for rc in reward_categories:
            try:
                rate = rc.rewardrate
                reward_info = {
                    'category': rc.merchant_category.name,
                    'cashback_percentage': float(rate.cashback_percentage) if rate.cashback_percentage else None,
                    'points': rate.points if rate.points else None,
                    'reset_period': rate.reset_period if rate.reset_period else None,
                    'limit': float(rate.limit) if rate.limit else None
                }
                card_data['rewards'].append(reward_info)
            except RewardRate.DoesNotExist:
                continue

        print(f"📊 Card has {len(card_data['rewards'])} reward categories")

        # Prepare prompt for GPT
        prompt = build_card_details_prompt(card_data)

        # Initialize Grok client
        if not os.environ.get('XAI_API_KEY'):
            return Response({'error': 'Grok API key not configured'}, status=500)

        client = Client()

        # Get RAG tools if configured
        tools = get_rag_tools()
        if tools:
            print(f"✅ RAG enabled - Collection ID: {getattr(settings, 'CARD_BENEFITS_COLLECTION_ID', None)}")
            print(f"📚 RAG will search PDFs for: {card_data['name']}")
        else:
            print(f"⚠️  RAG disabled - No collection ID configured")

        def event_stream():
            """Generator function for Server-Sent Events"""
            try:
                # Use grok-4 if we have RAG tools, grok-3 otherwise
                model = "grok-4" if tools else "grok-3"
                print(f"🔄 Starting stream with model: {model}, RAG tools: {bool(tools)}")

                # Call Grok API with streaming enabled
                chat = client.chat.create(
                    model=model,
                    messages=[
                        system("You are a credit card expert who provides detailed, accurate information about credit card benefits and features. CRITICAL: Use the collections_search tool to look up official card benefit documentation for accurate, up-to-date information. Always prioritize information from official documents over general knowledge. Always respond with valid JSON."),
                        xai_user(prompt)
                    ],
                    tools=tools if tools else None
                )

                accumulated_content = ""

                # Stream the response
                for response, chunk in chat.stream():
                    if chunk.content:
                        accumulated_content += chunk.content
                        # Send chunk as SSE (Server-Sent Event)
                        yield f"data: {json.dumps({'chunk': chunk.content})}\n\n"

                # Log if RAG tool was used (check final response)
                if tools and hasattr(response, 'tool_calls') and response.tool_calls:
                    print(f"🔍 RAG tool was invoked {len(response.tool_calls)} time(s)")

                # Send completion signal
                yield f"data: {json.dumps({'done': True, 'full_response': accumulated_content})}\n\n"

                print(f"✅ GPT Card Details Streaming complete - streamed {len(accumulated_content)} characters")

            except Exception as e:
                print(f"❌ Error in streaming: {str(e)}")
                import traceback
                traceback.print_exc()
                error_data = json.dumps({'error': str(e)})
                yield f"data: {error_data}\n\n"

        # Return StreamingHttpResponse with SSE
        response = StreamingHttpResponse(event_stream(), content_type='text/event-stream')
        response['Cache-Control'] = 'no-cache'
        response['X-Accel-Buffering'] = 'no'
        return response

    except Exception as e:
        print(f"❌ Error in card details streaming: {str(e)}")
        return Response({
            'error': 'Internal server error during card details streaming',
            'details': str(e)
        }, status=500)
