#!/usr/bin/env python3
"""
Simple test script for the GPT-powered streaming card analysis endpoint.
This script demonstrates how to use the new streaming endpoint with Server-Sent Events.
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust if your server runs on a different port
ENDPOINT = f"{BASE_URL}/analyze-cards-with-gpt-streaming/"

# You'll need to get a valid JWT token from your authentication system
# For testing, you might want to use Django's test client or get a token via login
AUTH_TOKEN = "your-jwt-token-here"  # Replace with actual token

def test_streaming_endpoint():
    """Test the GPT streaming card analysis endpoint"""

    # Sample request parameters
    params = {
        "types": ["restaurant"],  # Example types
        # Optional: add store information
        # "store_name": "Chipotle",
        # "store_address": "123 Main St, San Francisco, CA"
    }

    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}",
        "Accept": "text/event-stream"
    }

    try:
        print(f"🚀 Testing GPT Streaming endpoint: {ENDPOINT}")
        print(f"📤 Request params: {params}")
        print("=" * 80)

        # Use stream=True to handle Server-Sent Events
        response = requests.get(ENDPOINT, params=params, headers=headers, stream=True)

        print(f"📥 Response status: {response.status_code}")

        if response.status_code == 200:
            print("✅ Connection successful! Streaming response...\n")

            accumulated_response = ""
            ranking_received = False
            analysis_received = False

            # Process the streaming response
            for line in response.iter_lines():
                if line:
                    line_str = line.decode('utf-8')

                    # SSE format: "data: {json}"
                    if line_str.startswith('data: '):
                        data_str = line_str[6:]  # Remove "data: " prefix

                        try:
                            data = json.loads(data_str)

                            # Check if this is a chunk
                            if 'chunk' in data:
                                chunk = data['chunk']
                                accumulated_response += chunk
                                print(chunk, end='', flush=True)

                                # Try to parse as JSON to detect when ranking is complete
                                if not ranking_received and '"ranking"' in accumulated_response:
                                    print("\n\n🎯 Ranking section detected!")
                                    ranking_received = True

                                if not analysis_received and '"analysis"' in accumulated_response:
                                    print("\n\n📊 Analysis section detected!")
                                    analysis_received = True

                            # Check if streaming is complete
                            elif 'done' in data and data['done']:
                                print("\n\n" + "=" * 80)
                                print("✅ Streaming complete!")

                                # Parse the full response
                                try:
                                    full_data = json.loads(accumulated_response)

                                    # Display ranking
                                    if 'ranking' in full_data:
                                        print(f"\n🏆 CARD RANKING ({len(full_data['ranking'])} cards):")
                                        for i, card in enumerate(full_data['ranking'], 1):
                                            print(f"   {i}. {card.get('card_name')} - {card.get('issuer')}")

                                    # Display analysis summary
                                    if 'analysis' in full_data:
                                        print(f"\n📊 DETAILED ANALYSIS ({len(full_data['analysis'])} cards):")
                                        for i, analysis in enumerate(full_data['analysis'], 1):
                                            print(f"\n   🏆 Rank #{i}: {analysis.get('card_name')}")
                                            print(f"      Issuer: {analysis.get('issuer')}")
                                            print(f"      Value: {analysis.get('value')}")
                                            print(f"      Reward Type: {analysis.get('reward_type')}")
                                            print(f"      Reward Amount: {analysis.get('reward_amount')}")
                                            print(f"      Category: {analysis.get('category')}")
                                            if analysis.get('benefits'):
                                                print(f"      Benefits: {', '.join(analysis.get('benefits', []))}")
                                            print(f"      Explanation: {analysis.get('explanation')}")
                                            print(f"      Estimated Value: {analysis.get('estimated_value')}")
                                            if analysis.get('limitations'):
                                                print(f"      Limitations: {', '.join(analysis.get('limitations', []))}")

                                except json.JSONDecodeError as e:
                                    print(f"\n⚠️  Could not parse full JSON response: {e}")
                                    print(f"Raw response:\n{accumulated_response}")

                            # Check for errors
                            elif 'error' in data:
                                print(f"\n❌ Error from server: {data['error']}")

                        except json.JSONDecodeError:
                            # Might be partial JSON, continue accumulating
                            pass

            print("\n" + "=" * 80)
            print(f"📊 Total characters received: {len(accumulated_response)}")

        else:
            print("❌ Request failed!")
            print(f"Response: {response.text}")

    except requests.exceptions.ConnectionError:
        print("❌ Connection error - make sure your Django server is running")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

def test_without_auth():
    """Test endpoint without authentication (should fail)"""
    params = {
        "types": ["restaurant"]
    }

    try:
        response = requests.get(ENDPOINT, params=params)
        print(f"🔒 No auth test - Status: {response.status_code}")
        if response.status_code == 401 or response.status_code == 403:
            print("✅ Authentication required (as expected)")
        else:
            print("❌ Expected 401/403 but got different status")
    except Exception as e:
        print(f"❌ Error: {str(e)}")

def test_invalid_data():
    """Test endpoint with invalid data"""
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}"
    }

    # Test with missing types parameter
    try:
        response = requests.get(ENDPOINT, headers=headers)
        print(f"🔍 Missing types test - Status: {response.status_code}")
        if response.status_code == 400:
            print("✅ Validation working (as expected)")
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    print("🧪 Testing GPT Streaming Card Analysis Endpoint")
    print("=" * 80)

    print("\n1. Testing without authentication:")
    test_without_auth()

    print("\n2. Testing with invalid data:")
    test_invalid_data()

    print("\n3. Testing streaming with valid data:")
    print("   Note: You need to set a valid AUTH_TOKEN and have user cards for this to work")
    test_streaming_endpoint()

    print("\n" + "=" * 80)
    print("🏁 Testing complete!")
