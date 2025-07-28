# Product Specifications

This folder contains comprehensive product specification documents for the Project Xtara career recommendation system.

## Documents

### 1. RAG Career Recommendation System Specification
**File**: `rag_career_recommendation_system_spec.md`

A comprehensive specification document for the Enhanced RAG (Retrieval-Augmented Generation) Career Recommendation System, including:

- **Executive Summary**: Product overview, key features, and target users
- **System Architecture**: Technology stack and component diagrams
- **Functional Requirements**: Core functionality and data structures
- **Technical Specifications**: Scoring algorithms, API endpoints, and performance requirements
- **Data Management**: Database design and analytics
- **Security and Privacy**: Data protection and compliance
- **User Experience**: Assessment flow and recommendation display
- **Quality Assurance**: Testing strategy and metrics
- **Deployment and Operations**: Environment management and monitoring
- **Future Enhancements**: Planned features and scalability roadmap
- **Success Metrics**: KPIs and success criteria
- **Implementation Details**: Core components and configuration

## Key Features Documented

### Conditional Scoring Algorithm
- **Grade 10 Students**: 60% academic factors, 30% personal factors, 10% demographic factors
- **Grade 12 Students**: 40% academic factors, 10% stream matching, 30% personal factors, 10% demographic factors

### Dual-Mode Search
- **Vector Search**: Semantic similarity using Vertex AI
- **Tag-based Matching**: Structured matching using Firestore

### Comprehensive Assessment
- 20+ assessment parameters
- Grade-specific academic evaluation
- Personal interests and personality traits
- Family context and financial background

## Technology Stack

- **Frontend**: Flutter (Mobile App)
- **Backend**: Firebase Cloud Functions (Node.js)
- **AI Services**: Google Vertex AI (Gemini 2.0 Flash)
- **Database**: Firestore (NoSQL)
- **Search**: Vector Search + Tag-based Matching
- **Hosting**: Firebase Hosting

## Performance Requirements

- **Response Time**: < 5 seconds for career recommendations
- **Scalability**: 1000+ concurrent users
- **Reliability**: 99.9% uptime, < 1% error rate
- **Data Storage**: 1GB+ career data

## Target Users

- **Primary**: Indian students in Grades 10-12
- **Secondary**: Career counselors and educational institutions
- **Tertiary**: Parents and guardians seeking career guidance

## Success Metrics

- **User Adoption**: 10,000+ active students within 6 months
- **Recommendation Accuracy**: 85%+ user satisfaction rate
- **Technical Performance**: 99.9% uptime and < 5 second response times
- **Educational Impact**: Measurable improvement in career decision-making

---

**Last Updated**: December 2024  
**Document Version**: 1.0  
**Next Review**: March 2025 