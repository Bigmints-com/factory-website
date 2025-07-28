# Technical Architecture: RAG Career Recommendation System

## System Overview

The RAG Career Recommendation System is built on a modern, scalable architecture that combines Firebase Cloud Functions with Google Vertex AI to provide intelligent career recommendations for Indian students.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER MOBILE APP                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   Assessment    │  │  Career Results │  │      User Profile          │  │
│  │     Module      │  │     Display     │  │       Management           │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FIREBASE CLOUD FUNCTIONS                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │ generateCareer  │  │   RAG Service   │  │   FirestoreMatchingService  │  │
│  │   PathRAG       │  │                 │  │                             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  Validation     │  │   Environment   │  │      Analytics &           │  │
│  │   Service       │  │   Config        │  │      Monitoring            │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GOOGLE VERTEX AI                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   Gemini 2.0    │  │   Vector Search │  │      Embedding Model       │  │
│  │   Flash Model   │  │   (Optional)    │  │     (text-embedding-005)   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FIRESTORE DATABASE                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   dream_careers │  │  career_paths   │  │        ai_calls             │  │
│  │   Collection    │  │   Collection    │  │      Collection             │  │
│  │   (500+ docs)   │  │   (User data)   │  │     (Analytics)            │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Flutter Mobile App

#### 1.1 Assessment Module
- **Purpose**: Collect comprehensive student assessment data
- **Features**:
  - Multi-step assessment flow
  - Grade-specific academic evaluation
  - Personal interests and personality assessment
  - Family context and financial background
- **Data Collection**: 20+ assessment parameters

#### 1.2 Career Results Display
- **Purpose**: Present personalized career recommendations
- **Features**:
  - Primary career path with detailed steps
  - 4 related career recommendations
  - Match scores and reasoning
  - Next steps and actionable tips

#### 1.3 User Profile Management
- **Purpose**: Manage user data and preferences
- **Features**:
  - User authentication
  - Profile updates
  - Assessment history
  - Career path tracking

### 2. Firebase Cloud Functions

#### 2.1 generateCareerPathRAG
```javascript
exports.generateCareerPathRAG = onCall({
  timeoutSeconds: 540,
  memory: "2GB"
}, async (request) => {
  // Main entry point for career recommendations
  // 1. Validate assessment data
  // 2. Query matching careers
  // 3. Generate AI response
  // 4. Store results
  // 5. Return formatted response
});
```

**Key Features**:
- **Timeout**: 9 minutes for complex AI processing
- **Memory**: 2GB allocation for large models
- **Authentication**: Firebase Auth integration
- **Error Handling**: Graceful degradation and fallbacks

#### 2.2 RAG Service
```javascript
class RAGService {
  async queryTopCareers(profile, useVectorSearch, numResults, customWeights) {
    // Dual-mode search implementation
    if (useVectorSearch) {
      return await this.queryCareerVectors(embedding, profile, numResults);
    } else {
      return await this.firestoreService.queryDreamCareers(profile, customWeights, numResults);
    }
  }
}
```

**Key Features**:
- **Dual-Mode Search**: Vector search or tag-based matching
- **Configurable**: Environment-based search mode selection
- **Performance**: Optimized for sub-5 second response times
- **Fallback**: Automatic fallback to tag-based matching

#### 2.3 FirestoreMatchingService
```javascript
class FirestoreMatchingService {
  computeMatchScore(career, profile, weights) {
    // Conditional scoring based on current grade
    const currentGrade = profile.currentGrade;
    
    if (currentGrade === "grade10") {
      // Grade 10 scoring: 60% academic factors
      return this.computeGrade10Score(career, profile, weights);
    } else if (currentGrade === "grade12") {
      // Grade 12 scoring: 40% academic + 10% stream
      return this.computeGrade12Score(career, profile, weights);
    }
  }
}
```

**Key Features**:
- **Conditional Scoring**: Different algorithms for Grade 10 vs Grade 12
- **Comprehensive Matching**: 20+ assessment parameters
- **Performance**: Logarithmic scoring for diminishing returns
- **Debugging**: Detailed scoring breakdown logs

### 3. Google Vertex AI

#### 3.1 Gemini 2.0 Flash Model
- **Purpose**: Generate personalized career recommendations
- **Configuration**:
  - **Model**: `gemini-2.0-flash-001`
  - **Max Tokens**: 4096
  - **Temperature**: 0.3 (balanced creativity)
  - **Top-p**: 0.8
  - **Top-k**: 40

#### 3.2 Vector Search (Optional)
- **Purpose**: Semantic similarity matching
- **Configuration**:
  - **Model**: `text-embedding-005`
  - **Dimensions**: 768
  - **Index**: Career vectors with metadata
  - **Endpoint**: Public endpoint for low-latency access

### 4. Firestore Database

#### 4.1 dream_careers Collection
```javascript
{
  "id": "aerospace_scientist",
  "title": "Aerospace Scientist",
  "description": "Conducts research in aircraft and spacecraft...",
  "interestTags": ["solvingProblems", "analyzingData"],
  "activityTags": ["reading", "gaming", "hiking"],
  "archetypeTags": ["analytical", "organized"],
  "goalTags": ["makeImpact", "earnWell"],
  "strengthTags": ["physics", "mathematics"],
  "weaknessAvoidTags": ["english", "history"],
  "recommendedStream": ["Science"],
  "gradeFit": ["grade10", "grade12", "graduate"],
  "preferredGenderTags": ["male", "female"],
  "financialFeasibility": {
    "lowerIncome": false,
    "middleClass": true,
    "upperMiddleClass": true
  },
  "careerCluster": "🧪 Innovators & Scientists",
  "parentalApproval": "medium",
  "prestigeLevel": "high",
  "careerStability": "high"
}
```

**Key Features**:
- **500+ Career Profiles**: Comprehensive career database
- **Structured Data**: 20+ fields per career
- **Optimized Indexing**: Tag-based query optimization
- **Metadata Rich**: Cultural, financial, and demographic data

#### 4.2 career_paths Collection
```javascript
{
  "userId": "user123",
  "assessmentId": "assessment456",
  "title": "Data Scientist",
  "description": "Personalized career recommendation...",
  "careerPath": {
    "steps": [...],
    "totalSteps": 5,
    "estimatedDuration": "3-5 years"
  },
  "relatedCareers": [...],
  "nextSteps": [...],
  "tips": [...],
  "ragOutput": {
    "searchMode": "firestore_matching_service",
    "searchResults": [...],
    "matchingDetails": {...}
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Key Features**:
- **User-Specific**: Individual career recommendations
- **Assessment-Linked**: Tied to specific assessment sessions
- **RAG Metadata**: Complete search and matching details
- **Audit Trail**: Creation and update timestamps

#### 4.3 ai_calls Collection
```javascript
{
  "userId": "user123",
  "assessmentId": "assessment456",
  "type": "rag_career_recommendation",
  "input": {...},
  "output": {...},
  "ragOutput": {...},
  "timestamp": "timestamp",
  "processingTime": 3200,
  "success": true
}
```

**Key Features**:
- **Analytics**: Performance and usage tracking
- **Debugging**: Input/output data for troubleshooting
- **Monitoring**: Response times and success rates
- **Compliance**: Audit trail for data processing

## Data Flow

### 1. Assessment Flow
```
Student Input → Flutter App → Firebase Functions → Validation → Processing
```

### 2. Career Matching Flow
```
Assessment Data → FirestoreMatchingService → Career Scoring → Top 5 Results
```

### 3. AI Generation Flow
```
Matched Careers → RAG Prompt → Vertex AI → Response Parsing → Storage
```

### 4. Response Flow
```
AI Response → Validation → Formatting → Flutter App → User Display
```

## Performance Characteristics

### Response Times
- **Career Matching**: < 2 seconds
- **AI Generation**: < 3 seconds
- **Total Response**: < 5 seconds

### Scalability
- **Concurrent Users**: 1000+
- **Daily Requests**: 10,000+
- **Data Processing**: Real-time

### Reliability
- **Uptime**: 99.9%
- **Error Rate**: < 1%
- **Fallback**: Graceful degradation

## Security Architecture

### Authentication
- **Firebase Auth**: User authentication and authorization
- **JWT Tokens**: Secure API access
- **Role-Based Access**: User-specific data access

### Data Protection
- **Encryption**: AES-256 at rest, TLS 1.3 in transit
- **Privacy**: GDPR and COPPA compliance
- **Consent**: Explicit user consent for data processing

### Network Security
- **HTTPS**: All communications encrypted
- **CORS**: Controlled cross-origin access
- **Rate Limiting**: Protection against abuse

## Monitoring and Analytics

### Application Monitoring
- **Firebase Performance**: Response time tracking
- **Error Tracking**: Crashlytics integration
- **Logging**: Structured logging with severity levels

### Business Analytics
- **User Engagement**: Daily active users, session duration
- **Recommendation Quality**: User satisfaction scores
- **Technical Performance**: Response times, error rates

### Alerting
- **Real-time Alerts**: Critical issue notifications
- **Performance Thresholds**: Response time monitoring
- **Error Rate Tracking**: Quality assurance alerts

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025 