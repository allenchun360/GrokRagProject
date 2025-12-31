"""
Test script to verify if streaming works with collections_search tool
"""
import os
from dotenv import load_dotenv
from xai_sdk import Client
from xai_sdk.chat import system, user
from xai_sdk.tools import collections_search

load_dotenv()

collection_id = os.environ.get('CARD_BENEFITS_COLLECTION_ID')
print(f"Testing with collection ID: {collection_id}")

client = Client()

# Test 1: Try streaming with tools
print("\n=== Test 1: Streaming with collections_search tool ===")
try:
    chat = client.chat.create(
        model="grok-4",
        messages=[
            system("You are a helpful assistant. Use the collections_search tool to find information."),
            user("What are the benefits of the Robinhood Gold Card for dining?")
        ],
        tools=[
            collections_search(
                collection_ids=[collection_id],
                retrieval_mode="hybrid",
            )
        ],
    )

    print("Attempting to stream...")
    chunk_count = 0
    for response, chunk in chat.stream():
        if chunk.content:
            print(f"Chunk {chunk_count}: {chunk.content[:50]}...")
            chunk_count += 1

    print(f"✅ Streaming worked! Received {chunk_count} chunks")

    # Check if tool was called
    if hasattr(response, 'tool_calls') and response.tool_calls:
        print(f"🔍 Tool was called {len(response.tool_calls)} time(s)")
    else:
        print("⚠️  Tool was NOT called")

except Exception as e:
    print(f"❌ Streaming failed: {str(e)}")
    import traceback
    traceback.print_exc()

# Test 2: Try sample() with tools
print("\n=== Test 2: Sample with collections_search tool ===")
try:
    chat2 = client.chat.create(
        model="grok-4",
        messages=[
            system("You are a helpful assistant. Use the collections_search tool to find information."),
            user("What are the benefits of the Robinhood Gold Card for dining?")
        ],
        tools=[
            collections_search(
                collection_ids=[collection_id],
                retrieval_mode="hybrid",
            )
        ],
    )

    print("Using sample()...")
    response = chat2.sample()
    print(f"✅ Sample worked! Response length: {len(response.content)}")

    if hasattr(response, 'tool_calls') and response.tool_calls:
        print(f"🔍 Tool was called {len(response.tool_calls)} time(s)")
    else:
        print("⚠️  Tool was NOT called")

except Exception as e:
    print(f"❌ Sample failed: {str(e)}")
    import traceback
    traceback.print_exc()
