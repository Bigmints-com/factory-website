# Product Specification Document: Enhanced RAG Career Recommendation System

## 1. Executive Summary

### 1.1 Product Overview
The Enhanced RAG (Retrieval-Augmented Generation) Career Recommendation System is a sophisticated AI-powered career guidance platform designed specifically for Indian students. The system provides personalized career recommendations by combining semantic search with AI-generated career paths, using a comprehensive scoring algorithm that adapts to students' academic levels and personal profiles.

### 1.2 Key Features
- **Dual-Mode Search**: Vector-based semantic search and tag-based matching
- **Conditional Scoring**: Grade-specific recommendation algorithms
- **Comprehensive Assessment**: 20+ assessment parameters
- **Real-time Processing**: Sub-5 second response times
- **Scalable Architecture**: Firebase Cloud Functions with Vertex AI integration

### 1.3 Target Users
- **Primary**: Indian students in Grades 10-12
- **Secondary**: Career counselors and educational institutions
- **Tertiary**: Parents and guardians seeking career guidance

## 2. System Architecture

### 2.1 Technology Stack
```
Frontend: Flutter (Mobile App)
Backend: Firebase Cloud Functions (Node.js)
AI Services: Google Vertex AI (Gemini 2.0 Flash)
Database: Firestore (NoSQL)
Search: Vector Search + Tag-based Matching
Hosting: Firebase Hosting
```

### 2.2 System Components
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│  Firebase Cloud  │───▶│   Vertex AI     │
│                 │    │    Functions     │    │   (Gemini)      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │    Firestore     │
                       │  (Career Data)   │
                       └──────────────────┘
```

## 3. Functional Requirements

### 3.1 Core Functionality

#### 3.1.1 Career Recommendation Engine
**Purpose**: Generate personalized career recommendations based on student assessment data

**Input Parameters**:
- Student demographic information
- Academic strengths and weaknesses (grade-specific)
- Personal interests and personality traits
- Career goals and parental influence
- Financial background and education board

**Output**:
- Primary career path with detailed steps
- 4 related career recommendations
- Next steps and actionable tips
- Match scores and reasoning

#### 3.1.2 Conditional Scoring Algorithm
**Grade 10 Students**:
- Academic factors: 60% weight
- Personal factors: 30% weight
- Demographic factors: 10% weight

**Grade 12 Students**:
- Academic factors: 40% weight
- Stream matching: 10% weight
- Personal factors: 30% weight
- Demographic factors: 10% weight

### 3.2 Assessment Data Structure

```json
{
  "basicInfo": {
    "fullName": "string",
    "age": "number",
    "gender": "string",
    "currentGrade": "grade10|grade12",
    "educationBoard": "string",
    "financialBackground": "string"
  },
  "academicProfile": {
    "grade10Strengths": ["string"],
    "grade10Weaknesses": ["string"],
    "grade12Streams": "string",
    "grade12ScienceStrengths": ["string"],
    "grade12ScienceWeaknesses": ["string"],
    "grade12CommerceStrengths": ["string"],
    "grade12CommerceWeaknesses": ["string"],
    "grade12ArtsStrengths": ["string"],
    "grade12ArtsWeaknesses": ["string"]
  },
  "personalProfile": {
    "exciters": ["string"],
    "interests": ["string"],
    "personalityTraits": ["string"],
    "careerGoals": ["string"],
    "parentalInfluence": "string"
  }
}
```

### 3.3 Career Data Structure

```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "interestTags": ["string"],
  "activityTags": ["string"],
  "archetypeTags": ["string"],
  "goalTags": ["string"],
  "strengthTags": ["string"],
  "weaknessAvoidTags": ["string"],
  "recommendedStream": ["string"],
  "gradeFit": ["string"],
  "preferredGenderTags": ["string"],
  "financialFeasibility": "object",
  "careerCluster": "string",
  "parentalApproval": "string",
  "prestigeLevel": "string",
  "careerStability": "string"
}
```

## 4. Technical Specifications

### 4.1 Scoring Algorithm

#### 4.1.1 Weight Distribution
```javascript
const weights = {
  // Basic Demographics (10%)
  gender: 2.5,
  financialBackground: 5.0,
  educationBoard: 2.5,
  
  // Grade 10 Academic (60%)
  grade10SubjectStrengths: 30.0,
  grade10SubjectWeaknesses: 30.0,
  
  // Grade 12 Academic (40%)
  currentStream: 10.0,
  grade12SubjectStrengths: 15.0,
  grade12SubjectWeaknesses: 15.0,
  
  // Personal Factors (30%)
  exciters: 10.0,
  interests: 10.0,
  personalityTraits: 10.0,
  
  // Career Factors (10%)
  careerGoals: 5.0,
  parentalInfluence: 5.0
};
```

#### 4.1.2 Scoring Formula
```javascript
// Logarithmic scoring for diminishing returns
const logScore = (matches, weight) => Math.log2(Math.min(matches, 5) + 1) * weight;

// Final score calculation
finalScore = (baseScore * voteQuality) + jitter;
```

### 4.2 API Endpoints

#### 4.2.1 Generate Career Path (RAG)
```
POST /generateCareerPathRAG
Content-Type: application/json

Request:
{
  "assessmentData": "object",
  "customWeights": "object (optional)",
  "useVectorSearch": "boolean (optional)"
}

Response:
{
  "success": true,
  "data": {
    "id": "string",
    "title": "string",
    "description": "string",
    "careerPath": "object",
    "relatedCareers": ["object"],
    "nextSteps": ["string"],
    "tips": ["string"]
  },
  "ragOutput": {
    "searchMode": "string",
    "searchResults": ["object"],
    "matchingDetails": "object"
  }
}
```

### 4.3 Performance Requirements

#### 4.3.1 Response Times
- **Career Recommendation**: < 5 seconds
- **Search Results**: < 2 seconds
- **AI Generation**: < 3 seconds

#### 4.3.2 Scalability
- **Concurrent Users**: 1000+
- **Daily Requests**: 10,000+
- **Data Storage**: 1GB+ career data

#### 4.3.3 Reliability
- **Uptime**: 99.9%
- **Error Rate**: < 1%
- **Fallback Mechanisms**: Graceful degradation

## 5. Data Management

### 5.1 Career Database
- **Collection**: `dream_careers`
- **Documents**: 500+ career profiles
- **Fields**: 20+ structured fields per career
- **Indexing**: Optimized for tag-based queries

### 5.2 User Data Storage
- **Collection**: `career_paths`
- **Security**: User-specific access control
- **Retention**: 7 years (educational records)
- **Anonymization**: Optional for analytics

### 5.3 Analytics and Monitoring
- **Collection**: `ai_calls`
- **Metrics**: Response times, success rates, user engagement
- **Dashboards**: Real-time monitoring and insights

## 6. Security and Privacy

### 6.1 Data Protection
- **Encryption**: AES-256 for data at rest
- **Transit**: TLS 1.3 for data in transit
- **Authentication**: Firebase Auth integration
- **Authorization**: Role-based access control

### 6.2 Privacy Compliance
- **GDPR**: Data portability and deletion rights
- **COPPA**: Child privacy protection
- **Local Laws**: Indian data protection regulations
- **Consent**: Explicit user consent for data processing

## 7. User Experience

### 7.1 Assessment Flow
1. **Basic Information**: Demographics and academic level
2. **Academic Assessment**: Strengths and weaknesses by grade/stream
3. **Personal Assessment**: Interests, personality, and goals
4. **Family Context**: Parental influence and financial background
5. **Results**: Personalized career recommendations

### 7.2 Recommendation Display
- **Primary Career**: Detailed career path with steps
- **Related Careers**: 4 alternative options with reasoning
- **Action Items**: Specific next steps for students
- **Resources**: Links to courses, institutions, and tools

### 7.3 Accessibility
- **Screen Readers**: Full compatibility
- **Color Contrast**: WCAG 2.1 AA compliance
- **Keyboard Navigation**: Complete keyboard support
- **Multilingual**: Support for Indian languages

## 8. Quality Assurance

### 8.1 Testing Strategy
- **Unit Tests**: 90% code coverage
- **Integration Tests**: API endpoint validation
- **Performance Tests**: Load testing and stress testing
- **User Acceptance**: Beta testing with real students

### 8.2 Quality Metrics
- **Recommendation Accuracy**: Measured through user feedback
- **Response Time**: 95th percentile < 5 seconds
- **Error Rate**: < 1% of requests
- **User Satisfaction**: > 4.5/5 rating

### 8.3 Continuous Improvement
- **A/B Testing**: Algorithm optimization
- **User Feedback**: Regular surveys and interviews
- **Data Analysis**: Usage patterns and success metrics
- **Algorithm Updates**: Quarterly performance reviews

## 9. Deployment and Operations

### 9.1 Environment Management
- **Development**: Local development with Firebase emulators
- **Staging**: Production-like environment for testing
- **Production**: Firebase Cloud Functions with auto-scaling

### 9.2 Monitoring and Alerting
- **Application Monitoring**: Firebase Performance Monitoring
- **Error Tracking**: Firebase Crashlytics
- **Logging**: Structured logging with severity levels
- **Alerting**: Real-time notifications for critical issues

### 9.3 Backup and Recovery
- **Data Backup**: Daily automated backups
- **Disaster Recovery**: Multi-region redundancy
- **Rollback Strategy**: Version control and deployment rollbacks

## 10. Future Enhancements

### 10.1 Planned Features
- **Machine Learning**: Predictive career success modeling
- **Video Content**: Career exploration videos
- **Mentorship**: Connect students with professionals
- **Internship Matching**: Direct internship opportunities

### 10.2 Scalability Roadmap
- **Multi-language**: Support for regional languages
- **International**: Expansion to other countries
- **Enterprise**: B2B solutions for schools and colleges
- **Mobile App**: Native iOS and Android applications

## 11. Success Metrics

### 11.1 Key Performance Indicators
- **User Engagement**: Daily active users and session duration
- **Recommendation Quality**: User satisfaction and career path completion
- **Technical Performance**: Response times and error rates
- **Business Impact**: User growth and retention rates

### 11.2 Success Criteria
- **User Adoption**: 10,000+ active students within 6 months
- **Recommendation Accuracy**: 85%+ user satisfaction rate
- **Technical Performance**: 99.9% uptime and < 5 second response times
- **Educational Impact**: Measurable improvement in career decision-making

## 12. Implementation Details

### 12.1 Core Components

#### 12.1.1 FirestoreMatchingService
```javascript
class FirestoreMatchingService {
  async queryDreamCareers(studentProfile, customWeights, numResults = 5) {
    // Retrieves and scores careers based on student profile
    // Returns top 5 matching careers
  }
  
  computeMatchScore(career, profile, weights) {
    // Implements conditional scoring algorithm
    // Different weights for Grade 10 vs Grade 12
  }
}
```

#### 12.1.2 RAG Service
```javascript
class RAGService {
  async queryTopCareers(profile, useVectorSearch, numResults, customWeights) {
    // Dual-mode search implementation
    // Vector search or tag-based matching
  }
  
  buildPrompt(profile, matchedCareers) {
    // Creates AI prompt with career context
    // Includes all assessment data
  }
}
```

### 12.2 Configuration Management
```javascript
// Environment-specific configurations
const environments = {
  dev: {
    firestoreMatchWeights: { /* weights */ },
    useVectorSearch: true,
    dreamCareersCollection: "dream_careers"
  },
  prod: {
    firestoreMatchWeights: { /* weights */ },
    useVectorSearch: true,
    dreamCareersCollection: "dream_careers"
  }
};
```

### 12.3 Error Handling
- **Graceful Degradation**: Fallback to basic recommendations if AI fails
- **Retry Logic**: Automatic retries for transient failures
- **User Feedback**: Clear error messages and recovery options
- **Monitoring**: Comprehensive error tracking and alerting

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025  
**Author**: AI Assistant  
**Reviewers**: Development Team, Product Manager 