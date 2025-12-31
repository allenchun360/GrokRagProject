"""
Test script to verify RAG collection is working properly.
"""
import os
from django.conf import settings
from recommendation.rag_service import RAGService

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'card_recommendation.settings')
import django
django.setup()

def test_collection():
    """Test if the RAG collection can be searched"""
    collection_id = getattr(settings, 'CARD_BENEFITS_COLLECTION_ID', None)

    if not collection_id:
        print("❌ CARD_BENEFITS_COLLECTION_ID not found in settings")
        return

    print(f"✅ Collection ID: {collection_id}")

    rag = RAGService()

    # Test search
    test_queries = [
        "Bilt card rewards for lodging",
        "Chase Sapphire Preferred hotel rewards",
        "Robinhood Gold Card travel benefits"
    ]

    for query in test_queries:
        print(f"\n🔍 Testing query: {query}")
        try:
            results = rag.search(
                query=query,
                collection_ids=[collection_id],
                retrieval_mode="hybrid",
                top_k=3
            )

            if hasattr(results, 'results') and results.results:
                print(f"✅ Found {len(results.results)} results")
                for idx, result in enumerate(results.results[:2], 1):
                    text = result.text if hasattr(result, 'text') else str(result)
                    score = result.score if hasattr(result, 'score') else 'N/A'
                    print(f"\n  Result {idx} (score: {score}):")
                    print(f"  {text[:200]}...")
            else:
                print(f"⚠️  No results found")
                print(f"  Response: {results}")
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    test_collection()
