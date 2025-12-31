"""
Management command to upload card benefit PDFs to xAI collections.

Usage:
    # Create a collection and upload a single PDF
    python manage.py upload_card_pdfs --create-collection "Chase Sapphire Preferred" --pdf path/to/benefits.pdf

    # Upload PDF to existing collection
    python manage.py upload_card_pdfs --collection-id "col_xyz123" --pdf path/to/benefits.pdf

    # Upload multiple PDFs from a directory to existing collection
    python manage.py upload_card_pdfs --collection-id "col_xyz123" --pdf-dir path/to/pdfs/

    # Create collection and upload all PDFs from a directory
    python manage.py upload_card_pdfs --create-collection "All Cards" --pdf-dir path/to/pdfs/
"""
import os
from django.core.management.base import BaseCommand, CommandError
from recommendation.rag_service import RAGService


class Command(BaseCommand):
    help = 'Upload credit card benefit PDFs to xAI collections for RAG'

    def add_arguments(self, parser):
        # Collection options
        parser.add_argument(
            '--create-collection',
            type=str,
            help='Create a new collection with this name'
        )
        parser.add_argument(
            '--collection-id',
            type=str,
            help='Use existing collection ID'
        )

        # Document upload options
        parser.add_argument(
            '--pdf',
            type=str,
            help='Path to a single PDF file to upload'
        )
        parser.add_argument(
            '--pdf-dir',
            type=str,
            help='Path to directory containing PDF files to upload'
        )
        parser.add_argument(
            '--document-name',
            type=str,
            help='Custom name for the document (only for single PDF upload)'
        )

        # Model options
        parser.add_argument(
            '--model',
            type=str,
            default='grok-embedding-small',
            help='Embedding model to use (default: grok-embedding-small)'
        )

    def handle(self, *args, **options):
        rag_service = RAGService()

        # Determine collection ID
        collection_id = None
        if options['create_collection']:
            self.stdout.write(f"Creating collection: {options['create_collection']}")
            collection = rag_service.create_collection(
                name=options['create_collection'],
                model_name=options['model']
            )
            collection_id = collection.collection_id
            self.stdout.write(self.style.SUCCESS(
                f"✅ Collection created! ID: {collection_id}"
            ))
            self.stdout.write(self.style.WARNING(
                f"⚠️  IMPORTANT: Save this collection ID in your .env file or settings!"
            ))
        elif options['collection_id']:
            collection_id = options['collection_id']
            self.stdout.write(f"Using existing collection: {collection_id}")
        else:
            raise CommandError(
                "You must specify either --create-collection or --collection-id"
            )

        # Upload documents
        uploaded_count = 0

        if options['pdf']:
            # Upload single PDF
            pdf_path = options['pdf']
            if not os.path.exists(pdf_path):
                raise CommandError(f"PDF file not found: {pdf_path}")

            self.stdout.write(f"Uploading {pdf_path}...")
            document = rag_service.upload_document(
                collection_id=collection_id,
                file_path=pdf_path,
                document_name=options.get('document_name')
            )
            # Extract document ID from response (handle different response formats)
            doc_id = getattr(document, 'document_id', None) or getattr(document, 'id', None)
            if not doc_id and hasattr(document, 'file_metadata'):
                doc_id = document.file_metadata.file_id
            elif not doc_id:
                doc_id = "uploaded successfully"

            self.stdout.write(self.style.SUCCESS(
                f"✅ Uploaded: {doc_id}"
            ))
            uploaded_count = 1

        elif options['pdf_dir']:
            # Upload all PDFs from directory
            pdf_dir = options['pdf_dir']
            if not os.path.isdir(pdf_dir):
                raise CommandError(f"Directory not found: {pdf_dir}")

            pdf_files = [f for f in os.listdir(pdf_dir) if f.lower().endswith('.pdf')]
            if not pdf_files:
                raise CommandError(f"No PDF files found in {pdf_dir}")

            self.stdout.write(f"Found {len(pdf_files)} PDF files in {pdf_dir}")

            for pdf_file in pdf_files:
                pdf_path = os.path.join(pdf_dir, pdf_file)
                self.stdout.write(f"Uploading {pdf_file}...")

                try:
                    document = rag_service.upload_document(
                        collection_id=collection_id,
                        file_path=pdf_path
                    )
                    # Extract document ID from response (handle different response formats)
                    doc_id = getattr(document, 'document_id', None)
                    if not doc_id and hasattr(document, 'file_metadata'):
                        doc_id = document.file_metadata.file_id
                    elif not doc_id:
                        doc_id = "uploaded successfully"

                    self.stdout.write(self.style.SUCCESS(
                        f"  ✅ {pdf_file}: {doc_id}"
                    ))
                    uploaded_count += 1
                except Exception as e:
                    self.stdout.write(self.style.ERROR(
                        f"  ❌ Failed to upload {pdf_file}: {str(e)}"
                    ))

        else:
            raise CommandError(
                "You must specify either --pdf or --pdf-dir"
            )

        # Summary
        self.stdout.write("\n" + "="*50)
        self.stdout.write(self.style.SUCCESS(
            f"✅ Upload complete! {uploaded_count} document(s) uploaded"
        ))
        self.stdout.write(f"Collection ID: {collection_id}")
        self.stdout.write("\nNext steps:")
        self.stdout.write("1. Add this to your .env file:")
        self.stdout.write(f"   CARD_BENEFITS_COLLECTION_ID={collection_id}")
        self.stdout.write("2. Update your settings.py to load this environment variable")
        self.stdout.write("3. Use the collection ID in your views for RAG queries")
