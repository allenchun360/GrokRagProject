# RAG Setup Guide

This guide explains how to set up and use RAG (Retrieval-Augmented Generation) with xAI Collections to improve credit card recommendation accuracy using PDF documents.

## Overview

The system uses xAI's built-in RAG capabilities to automatically retrieve relevant information from uploaded card benefit PDFs when analyzing cards. This ensures Grok uses official, up-to-date card documentation instead of relying solely on general knowledge.

## How It Works

1. **Upload PDFs**: Card benefit documents are uploaded to an xAI Collection
2. **Automatic Retrieval**: When a user requests card analysis, xAI automatically searches the collection for relevant information
3. **Enhanced Responses**: Grok uses the retrieved documentation to provide accurate, source-based recommendations

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Prepare Your PDF Documents

Collect credit card benefit PDFs. Organize them in a directory, for example:
```
/path/to/card_pdfs/
  ├── chase_sapphire_preferred_benefits.pdf
  ├── amex_gold_benefits.pdf
  ├── citi_double_cash_benefits.pdf
  └── ...
```

### 3. Create Collection and Upload PDFs

Use the management command to create a collection and upload your PDFs:

```bash
# Upload all PDFs from a directory (creates new collection)
python manage.py upload_card_pdfs \
  --create-collection "Card Benefits" \
  --pdf-dir /path/to/card_pdfs/

# Upload a single PDF to existing collection
python manage.py upload_card_pdfs \
  --collection-id "col_xyz123" \
  --pdf path/to/benefits.pdf

# Upload with custom document name
python manage.py upload_card_pdfs \
  --collection-id "col_xyz123" \
  --pdf path/to/benefits.pdf \
  --document-name "Chase Sapphire Preferred Benefits"
```

**Important**: Save the collection ID that's displayed after creation!

### 4. Configure Environment Variables

Add the collection ID to your `.env` file:

```bash
# xAI Collections (for RAG)
CARD_BENEFITS_COLLECTION_ID=col_your_collection_id_here
```

### 5. Update Settings (Optional)

If not using `.env`, add to `settings.py`:

```python
CARD_BENEFITS_COLLECTION_ID = 'col_your_collection_id_here'
```

## How RAG is Used in the Application

### Automatic Integration

Once configured, RAG is automatically used in these endpoints:

1. **`/api/cards/analyze-gpt/`** - Card analysis for categories
2. **`/api/cards/analyze-gpt-streaming/`** - Streaming card analysis
3. **`/api/cards/<card_id>/details-streaming/`** - Card detail lookup

### Behind the Scenes

When RAG is enabled:
- The system passes `collections_search` as a tool to Grok
- Grok automatically searches the collection when needed
- Retrieved documentation is used to enhance responses
- No manual prompt engineering required!

Example from code:
```python
from xai_sdk.tools import collections_search

tools = [
    collections_search(
        collection_ids=[settings.CARD_BENEFITS_COLLECTION_ID],
        retrieval_mode="hybrid",
    )
]

chat = client.chat.create(
    model="grok-3",
    messages=[...],
    tools=tools  # xAI handles RAG automatically!
)
```

## Disabling RAG

To disable RAG:
1. Remove or comment out `CARD_BENEFITS_COLLECTION_ID` from `.env`
2. The system will automatically fall back to non-RAG mode

## Updating Documents

### Add New Documents

```bash
python manage.py upload_card_pdfs \
  --collection-id "col_xyz123" \
  --pdf /path/to/new_card_benefits.pdf
```

### Replace Documents

To update a card's benefits:
1. Delete the old document (you'll need the document ID)
2. Upload the new PDF

You can use the RAG service directly in a Django shell:
```python
from recommendation.rag_service import RAGService

rag = RAGService()
rag.delete_document('col_xyz123', 'doc_abc456')
rag.upload_document('col_xyz123', '/path/to/updated_benefits.pdf')
```

## Best Practices

### Document Naming

Use clear, consistent names for your PDFs:
- ✅ `chase_sapphire_preferred_benefits_2024.pdf`
- ✅ `amex_platinum_card_guide.pdf`
- ❌ `document1.pdf`
- ❌ `benefits.pdf`

### Document Quality

- Use official card benefit guides from issuers
- Include terms & conditions
- Keep documents up-to-date (check quarterly)
- Use text-based PDFs (not scanned images)

### Collection Organization

**Option 1: Single Collection (Recommended)**
- One collection for all card benefits
- Simpler to manage
- Good for most use cases

**Option 2: Multiple Collections**
- Separate collections by issuer or card type
- More complex but allows fine-grained control
- Update `get_rag_tools()` in `views.py` to use multiple collection IDs

## Troubleshooting

### RAG not working
- Check that `CARD_BENEFITS_COLLECTION_ID` is set in `.env`
- Verify the collection ID is correct
- Look for "✅ RAG enabled with collection search tool" in logs

### Poor results
- Upload more comprehensive benefit documents
- Use official issuer PDFs (higher quality)
- Try uploading updated/recent documents

### Upload fails
- Check file path is correct
- Ensure PDF is readable (not corrupted)
- Verify XAI_API_KEY is valid

## Advanced Usage

### Programmatic Access

You can use the RAG service in your own scripts:

```python
from recommendation.rag_service import RAGService

rag = RAGService()

# Create a collection
collection = rag.create_collection("My Collection")

# Upload document
doc = rag.upload_document(
    collection.collection_id,
    "/path/to/file.pdf",
    "Document Name"
)

# Search
results = rag.search(
    query="Chase Sapphire dining rewards",
    collection_ids=[collection.collection_id],
    top_k=3
)
```

### Custom Retrieval Modes

Modify `get_rag_tools()` in `views.py`:

```python
collections_search(
    collection_ids=[collection_id],
    retrieval_mode="vector",  # Options: "vector", "keyword", "hybrid"
)
```

- **hybrid** (default): Combines semantic and keyword search
- **vector**: Semantic similarity only
- **keyword**: Exact keyword matching only
