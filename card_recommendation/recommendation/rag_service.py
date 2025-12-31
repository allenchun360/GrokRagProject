"""
RAG service for retrieving credit card benefit information from xAI collections.
"""
import os
from xai_sdk import Client


class RAGService:
    """Service for interacting with xAI collections for RAG"""

    def __init__(self):
        """Initialize xAI client"""
        api_key = os.environ.get('XAI_API_KEY')
        if not api_key:
            raise ValueError('XAI_API_KEY environment variable not set')

        # Use XAI_MANAGEMENT_API_KEY if available, otherwise use XAI_API_KEY for both
        management_api_key = os.environ.get('XAI_MANAGEMENT_API_KEY', api_key)

        self.client = Client(
            api_key=api_key,
            management_api_key=management_api_key
        )

    def create_collection(self, name, model_name="grok-embedding-small"):
        """
        Create a new xAI collection.

        Args:
            name: Name of the collection
            model_name: Embedding model to use (default: grok-embedding-small)

        Returns:
            Collection object with collection_id
        """
        collection = self.client.collections.create(
            name=name,
            model_name=model_name
        )
        print(f"✅ Created collection: {name} (ID: {collection.collection_id})")
        return collection

    def upload_document(self, collection_id, file_path, document_name=None):
        """
        Upload a document to a collection.

        Args:
            collection_id: xAI collection ID
            file_path: Path to the PDF file
            document_name: Optional name for the document (defaults to filename)

        Returns:
            Document object with document_id
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")

        with open(file_path, 'rb') as f:
            file_data = f.read()

        name = document_name or os.path.basename(file_path)

        document = self.client.collections.upload_document(
            collection_id,
            name=name,
            data=file_data,
        )
        # Handle both response formats - some return document_id directly, others in an object
        doc_id = getattr(document, 'document_id', None) or getattr(document, 'id', str(document))
        print(f"✅ Uploaded document: {name} (ID: {doc_id}) to collection {collection_id}")
        return document

    def search(self, query, collection_ids, retrieval_mode="hybrid", top_k=5):
        """
        Search across collections for relevant information.

        Args:
            query: Search query
            collection_ids: List of collection IDs to search
            retrieval_mode: "hybrid", "vector", or "keyword" (default: hybrid)
            top_k: Number of results to return

        Returns:
            Search results with relevant document chunks
        """
        # Try with top_k, if it fails try without it
        try:
            results = self.client.collections.search(
                query=query,
                collection_ids=collection_ids,
                retrieval_mode=retrieval_mode,
                top_k=top_k,
            )
        except TypeError:
            # Fallback without top_k parameter
            results = self.client.collections.search(
                query=query,
                collection_ids=collection_ids,
                retrieval_mode=retrieval_mode,
            )
        return results

    def get_collection_context(self, query, collection_ids, top_k=5):
        """
        Get formatted context from collection search results.

        Args:
            query: Search query
            collection_ids: List of collection IDs to search
            top_k: Number of results to return

        Returns:
            Formatted string with relevant context from documents
        """
        results = self.search(query, collection_ids, top_k=top_k)

        if not results or not hasattr(results, 'results') or not results.results:
            return ""

        context_parts = []
        for idx, result in enumerate(results.results, 1):
            # Extract text from result
            text = result.text if hasattr(result, 'text') else str(result)
            score = result.score if hasattr(result, 'score') else 'N/A'

            context_parts.append(f"[Source {idx}] (Relevance: {score})\n{text}")

        context = "\n\n".join(context_parts)
        return context

    def delete_document(self, collection_id, document_id):
        """
        Delete a document from a collection.

        Args:
            collection_id: xAI collection ID
            document_id: Document ID to delete
        """
        self.client.collections.delete_document(collection_id, document_id)
        print(f"✅ Deleted document {document_id} from collection {collection_id}")

    def delete_collection(self, collection_id):
        """
        Delete an entire collection.

        Args:
            collection_id: xAI collection ID to delete
        """
        self.client.collections.delete(collection_id)
        print(f"✅ Deleted collection {collection_id}")
