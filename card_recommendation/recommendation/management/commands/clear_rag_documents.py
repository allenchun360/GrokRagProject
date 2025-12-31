"""
Management command to clear all documents from a xAI collection.

Usage:
    # Clear all documents from a collection
    python manage.py clear_rag_documents --collection-id "col_xyz123"

    # Clear documents and confirm
    python manage.py clear_rag_documents --collection-id "col_xyz123" --confirm
"""
from django.core.management.base import BaseCommand, CommandError
from recommendation.rag_service import RAGService


class Command(BaseCommand):
    help = 'Clear all documents from a xAI collection'

    def add_arguments(self, parser):
        parser.add_argument(
            '--collection-id',
            type=str,
            required=True,
            help='Collection ID to clear documents from'
        )
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Skip confirmation prompt'
        )

    def handle(self, *args, **options):
        collection_id = options['collection_id']
        rag_service = RAGService()

        self.stdout.write(f"Fetching documents from collection: {collection_id}")

        try:
            # List all documents in the collection
            collection_info = rag_service.client.collections.get(collection_id)

            # Get documents from the collection
            documents = []
            if hasattr(collection_info, 'documents'):
                documents = collection_info.documents
            elif hasattr(collection_info, 'files'):
                documents = collection_info.files

            if not documents:
                self.stdout.write(self.style.WARNING(
                    "No documents found in this collection."
                ))
                return

            self.stdout.write(f"Found {len(documents)} document(s):")
            for doc in documents:
                doc_id = getattr(doc, 'document_id', None) or getattr(doc, 'id', None) or getattr(doc, 'file_id', None)
                doc_name = getattr(doc, 'name', None) or getattr(doc, 'filename', 'Unknown')
                self.stdout.write(f"  - {doc_name} (ID: {doc_id})")

            # Confirm deletion
            if not options['confirm']:
                confirm = input(f"\nAre you sure you want to delete all {len(documents)} document(s)? (yes/no): ")
                if confirm.lower() != 'yes':
                    self.stdout.write(self.style.WARNING("Operation cancelled."))
                    return

            # Delete all documents
            deleted_count = 0
            failed_count = 0

            for doc in documents:
                doc_id = getattr(doc, 'document_id', None) or getattr(doc, 'id', None) or getattr(doc, 'file_id', None)
                doc_name = getattr(doc, 'name', None) or getattr(doc, 'filename', 'Unknown')

                try:
                    rag_service.delete_document(collection_id, doc_id)
                    self.stdout.write(self.style.SUCCESS(f"  ✅ Deleted: {doc_name}"))
                    deleted_count += 1
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"  ❌ Failed to delete {doc_name}: {str(e)}"))
                    failed_count += 1

            # Summary
            self.stdout.write("\n" + "="*50)
            self.stdout.write(self.style.SUCCESS(
                f"✅ Deletion complete! {deleted_count} document(s) deleted"
            ))
            if failed_count > 0:
                self.stdout.write(self.style.WARNING(
                    f"⚠️  {failed_count} document(s) failed to delete"
                ))
            self.stdout.write(f"\nCollection ID {collection_id} is now empty and ready for new documents.")

        except Exception as e:
            raise CommandError(f"Error accessing collection: {str(e)}")
