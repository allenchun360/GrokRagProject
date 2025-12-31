import requests
import os
import math
from uuid import UUID

from rest_framework.decorators import api_view

from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.decorators import permission_classes

from rest_framework import viewsets
from users.models import User, UserCard
from users.serializers import UserSerializer, UserCardSerializer
from users.permissions import StaffPermissions, IsAuthenticatedAndActive

from recommendation.models import Card

GOOGLE_PLACES_API_KEY = os.environ.get('GOOGLE_PLACES_API_KEY')

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    queryset = User.objects.all()
    permission_classes = [StaffPermissions]


class UserCardListView(generics.ListAPIView):
    serializer_class = UserCardSerializer
    permission_classes = [IsAuthenticatedAndActive]

    def get_queryset(self):
        return UserCard.objects.filter(user=self.request.user)


@api_view(['GET'])
@permission_classes([IsAuthenticatedAndActive])
def get_user(request):
    try:
        user = User.objects.get(username=request.user.username)
    except User.DoesNotExist:
        return Response("User not found. Please log in as a user.", status=404)

    user_serializer = UserSerializer(user)
    return Response(user_serializer.data, status=200)

@api_view(['PATCH'])
@permission_classes([IsAuthenticatedAndActive])
def update_user(request):
    try:
        user = User.objects.get(username=request.user.username)
    except User.DoesNotExist:
        return Response("User not found. Please log in as a user.", status=404)

    serializer = UserSerializer(user, data=request.data, partial=True)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # Extract the validated data from the serializer
    validated_data = serializer.validated_data

    # Update the user instance with the validated data
    for attr, value in validated_data.items():
        setattr(user, attr, value)

    # Save the user instance
    user.save()

    # Retrieve the updated user instance from the database
    instance = User.objects.get(id=user.id)

    # Serialize the updated user instance and return the response
    serializer = UserSerializer(instance)
    return Response({"user": serializer.data}, status=200)

@api_view(['DELETE'])
@permission_classes([IsAuthenticatedAndActive])
def delete_user(request):
    username = request.user.username
    request.user.delete()
    try:
        User.objects.get(username=username)
        return Response(status=400)
    except User.DoesNotExist:
        return Response(status=200)

@api_view(['POST'])
@permission_classes([IsAuthenticatedAndActive])
def create_user_cards(request):
    card_ids = request.data.get('card_ids')  # should be a list of UUIDs

    if not isinstance(card_ids, list):
        return Response({"error": "card_ids must be a list of UUIDs."}, status=400)

    # Validate that all items in the list are valid UUIDs
    try:
        card_ids = [UUID(str(card_id)) for card_id in card_ids]
    except (ValueError, TypeError):
        return Response({"error": "card_ids must be a list of valid UUIDs."}, status=400)

    user = request.user
    existing_card_ids = set(
        UserCard.objects.filter(user=user, card_model_id__in=card_ids).values_list('card_model_id', flat=True)
    )

    for card_id in card_ids:
        if card_id in existing_card_ids:
            continue  # skip duplicates
        try:
            card = Card.objects.get(id=card_id)
            UserCard.objects.create(
                user=user,
                card_model=card
            )
        except Card.DoesNotExist:
            continue  # Skip invalid card IDs

    all_user_cards = UserCard.objects.filter(user=user).order_by('-created_at')
    serializer = UserCardSerializer(all_user_cards, many=True)
    return Response({"data": serializer.data}, status=201)

@api_view(['DELETE'])
@permission_classes([IsAuthenticatedAndActive])
def delete_user_card(request, pk):
    try:
        user_card = UserCard.objects.get(pk=pk, user=request.user)
    except UserCard.DoesNotExist:
        return Response({"error": "Card not found or does not belong to user."}, status=404)

    user_card.delete()
    return Response({"message": "Card deleted."}, status=204)

def haversine_distance(lat1, lng1, lat2, lng2):
    # Radius of Earth in miles
    R = 3958.8
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lng2 - lng1)

    a = math.sin(delta_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def filter_types(types):
    return 'point_of_interest' in types and 'establishment' in types and len(types) > 2

@api_view(['GET'])
@permission_classes([IsAuthenticatedAndActive])
def get_nearby_stores(request):
    try:
        lat = float(request.query_params.get('lat'))
        lng = float(request.query_params.get('lng'))
        radius = request.query_params.get('radius', 100)

        # lat = 37.32498
        # lng = -121.94560

        url = (
            f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            f"?location={lat},{lng}&radius={radius}&key={GOOGLE_PLACES_API_KEY}"
        )

        res = requests.get(url)
        data = res.json()
        results = data.get("results", [])

        stores = []
        for result in results:
            name = result.get("name")
            geometry = result.get("geometry", {})
            location = geometry.get("location", {})
            store_lat = location.get("lat")
            store_lng = location.get("lng")
            categories = result.get("types", [])
            address = result.get("vicinity") or result.get("formatted_address", "Address not available")

            if name and store_lat and store_lng and filter_types(categories):
                distance = haversine_distance(lat, lng, store_lat, store_lng)
                stores.append({
                    "name": name,
                    "categories": categories,
                    "latitude": store_lat,
                    "longitude": store_lng,
                    "address": address,
                    "distance": round(distance, 1)
                })

        unique_stores = {s["name"]: s for s in stores}.values()
        print(unique_stores)
        top8 = list(unique_stores)[:8]

        return Response({"stores": top8}, status=200)

    except (TypeError, ValueError):
        return Response({"error": "Invalid latitude or longitude"}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticatedAndActive])
def get_online_stores(request):
    """
    Returns a hardcoded list of the top 15 most popular online stores.
    """
    online_stores = [
        {
            "name": "Amazon",
            "address": "Online",
            "categories": ["shopping", "ecommerce", "retail"]
        },
        {
            "name": "Netflix",
            "address": "Online",
            "categories": ["streaming", "entertainment", "subscription", "media"]
        },
        {
            "name": "Apple Store",
            "address": "Online",
            "categories": ["shopping", "electronics", "technology", "retail"]
        },
        {
            "name": "Etsy",
            "address": "Online",
            "categories": ["shopping", "ecommerce", "handmade", "marketplace"]
        },
        {
            "name": "Spotify",
            "address": "Online",
            "categories": ["streaming", "music", "subscription", "media"]
        },
        {
            "name": "Nike",
            "address": "Online",
            "categories": ["shopping", "sports", "apparel", "retail"]
        },
        {
            "name": "Disney+",
            "address": "Online",
            "categories": ["streaming", "entertainment", "subscription", "media"]
        },
        {
            "name": "Prime Video",
            "address": "Online",
            "categories": ["streaming", "entertainment", "subscription", "media"]
        },
        {
            "name": "Sephora",
            "address": "Online",
            "categories": ["shopping", "beauty", "cosmetics", "retail"]
        },
        {
            "name": "TikTok Shop",
            "address": "Online",
            "categories": ["shopping", "ecommerce", "social_commerce", "trendy"]
        },
    ]

    return Response({"stores": online_stores}, status=200)
