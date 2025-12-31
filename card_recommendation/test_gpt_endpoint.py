#!/usr/bin/env python3
"""
Simple test script for the GPT-powered card analysis endpoint.
This script demonstrates how to use the new endpoint.
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust if your server runs on a different port
ENDPOINT = f"{BASE_URL}/analyze-cards-with-gpt/"

# You'll need to get a valid JWT token from your authentication system
# For testing, you might want to use Django's test client or get a token via login
AUTH_TOKEN = "your-jwt-token-here"  # Replace with actual token

def test_gpt_endpoint():
    """Test the GPT card analysis endpoint"""
    
    # Sample request parameters (now using query parameters)
    params = {
        "types": ["restaurant", "pharmacy"]  # Example types
    }
    
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}"
    }
    
    try:
        print(f"🚀 Testing GPT endpoint: {ENDPOINT}")
        print(f"📤 Request params: {params}")
        
        response = requests.get(ENDPOINT, params=params, headers=headers)
        
        print(f"📥 Response status: {response.status_code}")
        print(f"📥 Response data: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Test successful!")
            data = response.json()
            print(f"📊 Analyzed {data.get('total_cards_analyzed', 0)} cards for category: {data.get('category')}")
            print(f"📋 Types requested: {data.get('types')}")
            
            for i, analysis in enumerate(data.get('analysis', []), 1):
                print(f"\n🏆 Rank #{i}: {analysis.get('card_name')}")
                print(f"   Issuer: {analysis.get('issuer')}")
                print(f"   Value: {analysis.get('value')}")
                print(f"   Reward Type: {analysis.get('reward_type')}")
                print(f"   Reward Amount: {analysis.get('reward_amount')}")
                print(f"   Category: {analysis.get('category')}")
                print(f"   Benefits: {', '.join(analysis.get('benefits', []))}")
                print(f"   Explanation: {analysis.get('explanation')}")
                print(f"   Estimated Value: {analysis.get('estimated_value')}")
                if analysis.get('limitations'):
                    print(f"   Limitations: {', '.join(analysis.get('limitations', []))}")
        else:
            print("❌ Test failed!")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - make sure your Django server is running")
    except Exception as e:
        print(f"❌ Error: {str(e)}")

def test_without_auth():
    """Test endpoint without authentication (should fail)"""
    test_data = {
        "card_ids": [1, 2, 3],
        "category": "dining"
    }
    
    try:
        response = requests.post(ENDPOINT, json=test_data)
        print(f"🔒 No auth test - Status: {response.status_code}")
        if response.status_code == 401:
            print("✅ Authentication required (as expected)")
        else:
            print("❌ Expected 401 but got different status")
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
    
    # Test with empty types
    try:
        response = requests.get(ENDPOINT, params={"types": []}, headers=headers)
        print(f"🔍 Empty types test - Status: {response.status_code}")
        if response.status_code == 400:
            print("✅ Validation working (as expected)")
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    print("🧪 Testing GPT Card Analysis Endpoint")
    print("=" * 50)
    
    print("\n1. Testing without authentication:")
    test_without_auth()
    
    print("\n2. Testing with invalid data:")
    test_invalid_data()
    
    print("\n3. Testing with valid data:")
    print("   Note: You need to set a valid AUTH_TOKEN and have user cards for this to work")
    test_gpt_endpoint()
    
    print("\n" + "=" * 50)
    print("🏁 Testing complete!")
