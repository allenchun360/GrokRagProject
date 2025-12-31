# Credit Card Recommendation System

A full-stack application that provides intelligent credit card recommendations based on spending categories and locations, powered by AI and RAG (Retrieval-Augmented Generation).

## 🎯 Features

### Core Features
- **Smart Card Recommendations**: Get personalized credit card suggestions based on merchant type and location
- **AI-Powered Analysis**: Leverages xAI's Grok model for detailed benefit analysis
- **RAG Integration**: Searches official card benefit PDFs for accurate, up-to-date information
- **Real-Time Streaming**: Server-Sent Events (SSE) for responsive user experience
- **Category Mapping**: Automatically maps 100+ merchant types to reward categories
- **Multi-Card Management**: Users can manage multiple credit cards in their wallet

### Advanced Features
- **GPS-Based Store Detection**: Find nearby stores and get recommendations
- **Online Merchant Support**: Recommendations for e-commerce purchases
- **Detailed Card Analysis**: Deep-dive into specific card benefits and limitations
- **Value Calculation**: Automatic reward value estimation (cashback % or points value)
- **Mystery Box Integration**: Special Robinhood card features

## 🏗️ Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS App (Swift)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │ Card Wallet  │  │ Store Finder │  │ Recommendations │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API / SSE
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Django Backend (Python)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              REST Framework Endpoints                │   │
│  │  • /cards/                                           │   │
│  │  • /user-cards/                                      │   │
│  │  • /get-card-benefits-by-types/                      │   │
│  │  • /analyze-cards-with-gpt-streaming/  (RAG)        │   │
│  │  • /card-details-streaming/<id>/       (RAG)        │   │
│  │  • /get-nearby-stores/                               │   │
│  │  • /get-online-stores/                               │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │   Models     │  │   Services   │  │   Utils         │   │
│  │  • Card      │  │  • RAG       │  │  • Prompts      │   │
│  │  • UserCard  │  │  • xAI       │  │  • Category Map │   │
│  │  • Reward    │  │              │  │                 │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌──────────────────┐          ┌──────────────────────┐
│   PostgreSQL     │          │   xAI Grok API       │
│   (Production)   │          │  ┌────────────────┐  │
│   SQLite (Dev)   │          │  │ Grok-4 Model   │  │
│                  │          │  └────────┬───────┘  │
│  • Cards         │          │           │          │
│  • Users         │          │  ┌────────▼───────┐  │
│  • Rewards       │          │  │ RAG Collection │  │
│  • Categories    │          │  │  • PDFs        │  │
└──────────────────┘          │  │  • Embeddings  │  │
                              │  └────────────────┘  │
                              └──────────────────────┘
```

## 🚀 Local Setup

### Prerequisites

- Python 3.9+
- Node.js 16+ (for any frontend tooling)
- PostgreSQL (for production) or SQLite (for development)
- Xcode 15+ (for iOS app development)
- Git

### Backend Setup (Django)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd card_recommendation
   ```

2. **Create and activate virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**

   Create a `.env` file in the project root:
   ```bash
   # Django
   SECRET_KEY=your-secret-key-here
   DEBUG=True

   # Database (optional - defaults to SQLite)
   DATABASE_URL=postgresql://user:password@localhost:5432/dbname

   # xAI API
   XAI_API_KEY=your-xai-api-key
   XAI_MANAGEMENT_API_KEY=your-xai-management-api-key  # Optional

   # RAG Collection
   CARD_BENEFITS_COLLECTION_ID=collection_xxx  # Set after creating collection
   ```

5. **Run migrations**
   ```bash
   python manage.py migrate
   ```

6. **Create superuser (optional)**
   ```bash
   python manage.py createsuperuser
   ```

7. **Load initial data (if available)**
   ```bash
   python manage.py loaddata initial_data.json  # If you have fixture files
   ```

8. **Run development server**
   ```bash
   python manage.py runserver
   ```

   The API will be available at `http://localhost:8000`

### Frontend Setup (iOS)

1. **Open Xcode project**
   ```bash
   cd CardRecommendation
   open CardRecommendation.xcodeproj
   ```

2. **Update API endpoint**

   In `APIServices.swift`, update the baseURL:
   ```swift
   private let baseURL = "http://localhost:8000"
   ```

3. **Build and run**
   - Select a simulator or device
   - Press `Cmd + R` to build and run

### RAG Setup (Optional but Recommended)

1. **Create a collection**
   ```bash
   python manage.py upload_card_pdfs \
     --create-collection "Credit Card Benefits" \
     --model grok-embedding-small
   ```

   Save the collection ID that's printed.

2. **Add collection ID to .env**
   ```bash
   CARD_BENEFITS_COLLECTION_ID=collection_xxx
   ```

3. **Upload card benefit PDFs**
   ```bash
   # Single PDF
   python manage.py upload_card_pdfs \
     --collection-id "collection_xxx" \
     --pdf path/to/card_benefits.pdf

   # Multiple PDFs from directory
   python manage.py upload_card_pdfs \
     --collection-id "collection_xxx" \
     --pdf-dir recommendation/management/commands/
   ```

4. **Verify upload**
   ```bash
   python manage.py shell
   >>> from recommendation.rag_service import RAGService
   >>> rag = RAGService()
   >>> collection = rag.client.collections.get("collection_xxx")
   >>> print(collection.documents)
   ```

See [RAG_ENDPOINTS.md](RAG_ENDPOINTS.md) for detailed RAG documentation.

## 📊 Database Schema

### Core Models

**Card**
- `id` (UUID, primary key)
- `name` (e.g., "Chase Sapphire Preferred")
- `issuer` (ForeignKey to Issuer)
- `base_point_value` (Decimal, point redemption value)

**UserCard**
- `id` (UUID, primary key)
- `user` (ForeignKey to User)
- `card_model` (ForeignKey to Card)
- `created_at` (DateTime)

**MerchantCategory**
- `id` (Integer, primary key)
- `name` (e.g., "dining", "lodging", "gas")

**RewardCategory**
- `id` (Integer, primary key)
- `card` (ForeignKey to Card)
- `merchant_category` (ForeignKey to MerchantCategory)

**RewardRate**
- `id` (Integer, primary key)
- `category` (OneToOne to RewardCategory)
- `cashback_percentage` (Decimal)
- `points` (Integer)
- `limit` (Decimal, optional)
- `reset_period` (String, optional)

## 🔌 API Endpoints

### Authentication
- `POST /send-phone-code/` - Send verification code
- `PATCH /register-verify-phone-code/` - Register with code
- `PATCH /login-verify-phone-code/` - Login with code
- `POST /api/token/refresh/` - Refresh JWT token

### User Management
- `GET /get-user/` - Get current user profile
- `PATCH /update-user/` - Update user profile
- `DELETE /delete-user/` - Delete user account

### Card Management
- `GET /cards/` - List all available cards
- `GET /user-cards/` - Get user's saved cards
- `POST /create-user-cards/` - Add cards to wallet
- `DELETE /delete-user-card/<id>/` - Remove card from wallet

### Recommendations
- `GET /get-card-benefits-by-types/` - Basic recommendations by category
  - Query params: `types` (list of merchant types)

- `GET /analyze-cards-with-gpt/` - AI analysis (non-streaming)
  - Query params: `types`, `store_name`, `store_address`

- `GET /analyze-cards-with-gpt-streaming/` - **AI analysis with RAG (streaming)**
  - Query params: `types`, `store_name`, `store_address`
  - Returns: SSE stream with JSON response

- `GET /card-details-streaming/<card_id>/` - **Card details with RAG (streaming)**
  - Returns: SSE stream with detailed card info

### Store Lookup
- `GET /get-nearby-stores/` - Find stores near GPS location
  - Query params: `lat`, `lng`, `radius`

- `GET /get-online-stores/` - Get list of online merchants

## 🧪 Testing

### Backend Tests
```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test recommendation
python manage.py test users

# With coverage
coverage run --source='.' manage.py test
coverage report
```

### Test RAG Functionality
```bash
# Test RAG service directly
python test_rag_collection.py

# Test streaming with tools
python test_rag_streaming.py

# Test specific endpoint
python test_streaming_endpoint.py
```

### Manual API Testing
```bash
# Using curl
curl -X GET "http://localhost:8000/cards/" \
  -H "Authorization: Bearer <token>"

# Using httpie
http GET http://localhost:8000/analyze-cards-with-gpt-streaming/ \
  types==dining \
  store_name=="The French Laundry" \
  Authorization:"Bearer <token>"
```

## 📱 iOS App Structure

```
CardRecommendation/
├── Models/
│   ├── User.swift
│   ├── Card.swift
│   ├── UserCard.swift
│   └── Store.swift
├── ViewModels/
│   ├── CardRecommendationViewModel.swift
│   ├── CardInfoViewModel.swift
│   └── UserViewModel.swift
├── Views/
│   ├── Auth/
│   ├── CardWallet/
│   ├── CardRecommendation/
│   │   ├── GPTAnalysisCardView.swift
│   │   └── RecommendationCardView.swift
│   └── Settings/
├── Services/
│   └── APIServices.swift
└── Utils/
    ├── LocationManager.swift
    └── NotificationManager.swift
```

## 🛠️ Management Commands

### Card PDF Management
```bash
# Upload single PDF
python manage.py upload_card_pdfs \
  --collection-id "collection_xxx" \
  --pdf path/to/card.pdf \
  --document-name "Card Name"

# Upload directory of PDFs
python manage.py upload_card_pdfs \
  --collection-id "collection_xxx" \
  --pdf-dir path/to/pdfs/

# Clear all documents
python manage.py clear_rag_documents \
  --collection-id "collection_xxx" \
  --confirm
```

### Data Management
```bash
# Import merchant categories
python manage.py import_mccs

# Sync from Heroku (if applicable)
python manage.py sync_from_heroku
```

## 🔧 Configuration

### Django Settings

Key settings in `settings.py`:

```python
# RAG Configuration
CARD_BENEFITS_COLLECTION_ID = os.environ.get('CARD_BENEFITS_COLLECTION_ID', None)

# JWT Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=60),
    'ROTATE_REFRESH_TOKENS': True,
}

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.AllowAny',
    )
}
```

### iOS Configuration

In `APIServices.swift`:

```swift
// Timeout for streaming requests
config.timeoutIntervalForRequest = 600  // 10 minutes
config.timeoutIntervalForResource = 600 // 10 minutes

// Base URL
private let baseURL = "http://localhost:8000"  // Dev
// private let baseURL = "https://your-app.herokuapp.com"  // Prod
```

## 📈 Performance

### Response Times

| Endpoint | Without RAG | With RAG |
|----------|-------------|----------|
| Basic recommendations | ~100ms | N/A |
| GPT analysis (non-streaming) | ~2-5s | ~10-30s |
| GPT streaming | ~2-5s | ~10-30s |
| Card details | ~100ms | ~10-30s |

### Optimization Tips

1. **Use RAG selectively** - Only for critical accuracy needs
2. **Cache common queries** - Store frequent recommendations
3. **Batch requests** - Group multiple card lookups
4. **Index optimization** - Ensure database indexes on foreign keys
5. **Connection pooling** - Configure PostgreSQL connections

## 🚢 Deployment

### Heroku Deployment

1. **Create Heroku app**
   ```bash
   heroku create your-app-name
   ```

2. **Set environment variables**
   ```bash
   heroku config:set SECRET_KEY=xxx
   heroku config:set XAI_API_KEY=xxx
   heroku config:set CARD_BENEFITS_COLLECTION_ID=xxx
   ```

3. **Deploy**
   ```bash
   git push heroku main
   ```

4. **Run migrations**
   ```bash
   heroku run python manage.py migrate
   ```

### iOS App Store

1. Update `baseURL` to production URL
2. Archive build (Product → Archive)
3. Validate and upload to App Store Connect
4. Submit for review

## 🔐 Security

### Best Practices

- ✅ JWT authentication for all protected endpoints
- ✅ CORS configuration for allowed origins
- ✅ Environment variables for secrets
- ✅ HTTPS in production
- ✅ Input validation and sanitization
- ✅ Rate limiting (recommended)
- ✅ SQL injection prevention (Django ORM)
- ✅ XSS prevention (DRF serializers)

### Token Management

- Access tokens expire after 15 minutes
- Refresh tokens expire after 60 days
- Automatic token refresh on 401 responses
- Secure storage in iOS Keychain

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [xAI](https://x.ai/) for Grok API and RAG capabilities
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Django](https://www.djangoproject.com/)
- Credit card issuers for benefit documentation

## 📚 Additional Documentation

- [RAG Endpoints Documentation](RAG_ENDPOINTS.md) - Detailed RAG implementation guide
- [API Reference](API_REFERENCE.md) - Complete API documentation (if available)
- [Deployment Guide](DEPLOYMENT.md) - Production deployment instructions (if available)

## 🐛 Troubleshooting

### Common Issues

**"No module named 'django'"**
- Solution: Activate virtual environment (`source venv/bin/activate`)

**"RAG disabled - No collection ID configured"**
- Solution: Set `CARD_BENEFITS_COLLECTION_ID` in `.env`

**"Connection refused" from iOS app**
- Solution: Update `baseURL` to correct backend URL

**Timeout on streaming requests**
- Solution: Check `timeoutIntervalForRequest` is set to 600s

**"Database is locked" (SQLite)**
- Solution: Switch to PostgreSQL for production or ensure single process access

For more troubleshooting, see [RAG_ENDPOINTS.md](RAG_ENDPOINTS.md#troubleshooting).

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Check existing documentation

---

**Built with using Django, Swift, and xAI**
