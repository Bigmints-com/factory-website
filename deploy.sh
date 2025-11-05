#!/bin/bash

# LeadForm Platform Cloud Run Deployment Script
# This script builds, tests, and deploys the LeadForm Platform to Google Cloud Run

set -e  # Exit on any error

# Configuration
PROJECT_ID="dvizfb"
SERVICE_NAME="leadform-platform"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"
SERVICE_URL="https://$SERVICE_NAME-647930923087.$REGION.run.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Use gcloud directly (assuming it's in PATH)
    if ! command -v gcloud >/dev/null 2>&1; then
        print_error "gcloud CLI is not found in PATH. Please ensure it's installed and accessible."
        exit 1
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found. Please run 'gcloud auth login'"
        exit 1
    fi
    
    # Check if project is set
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
        print_warning "Setting project to $PROJECT_ID"
        gcloud config set project $PROJECT_ID
    fi
    
    print_success "Prerequisites check passed"
}

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable containerregistry.googleapis.com
    
    print_success "APIs enabled"
}

# Function to build Docker image locally
build_local() {
    print_status "Building Docker image locally for linux/amd64..."
    
    # Build for linux/amd64 (required by Cloud Run)
    docker build --platform linux/amd64 -t leadform-platform:local .
    
    if [ $? -eq 0 ]; then
        print_success "Image built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Function to test Docker image locally
test_local() {
    if [ "$SKIP_LOCAL_TEST" = true ]; then
        print_warning "Skipping local Docker test"
        return
    fi
    
    print_status "Testing Docker image locally..."
    
    # Stop and remove any existing test container
    docker stop leadform-test 2>/dev/null || true
    docker rm leadform-test 2>/dev/null || true
    
    # Run container in background
    CONTAINER_ID=$(docker run -d -p 3000:3000 --name leadform-test leadform-platform:local)
    
    if [ $? -eq 0 ]; then
        print_success "Container started successfully"
        
        # Wait a moment for the container to start
        sleep 3
        
        # Test if the container is responding
        if curl -f http://localhost:3000 >/dev/null 2>&1; then
            print_success "Local test passed - container is responding"
        else
            print_warning "Container is running but not responding on port 3000"
        fi
        
        # Stop and remove test container
        print_status "Stopping test container..."
        docker stop leadform-test
        docker rm leadform-test
    else
        print_error "Failed to start container"
        exit 1
    fi
}

# Function to tag and push to GCR
push_to_gcr() {
    print_status "Tagging image for Google Container Registry..."
    
    docker tag leadform-platform:local $IMAGE_NAME
    
    print_status "Configuring Docker for GCR..."
    gcloud auth configure-docker --quiet
    
    print_status "Pushing image to Google Container Registry..."
    docker push $IMAGE_NAME
    
    if [ $? -eq 0 ]; then
        print_success "Image pushed successfully"
    else
        print_error "Push failed"
        exit 1
    fi
}

# Function to deploy to Cloud Run
deploy_to_cloud_run() {
    print_status "Deploying to Cloud Run..."
    
    # Read environment variables from .env.local if it exists
    ENV_VARS="NODE_ENV=production"
    
    # Note: Firebase and Google OAuth credentials are loaded from creds/ directory in the container
    # The Dockerfile includes the creds directory, so the app will read them automatically
    print_status "Credentials will be loaded from creds/ directory in the container"
    
    if [ -f .env.local ]; then
        print_status "Loading environment variables from .env.local..."
        # Extract key variables (excluding comments and empty lines)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes from value if present
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            # Add to ENV_VARS if it's a relevant variable (skip if already set from creds)
            case "$key" in
                FIRESTORE_DATABASE_ID|RESEND_API_KEY|RESEND_FROM_EMAIL|NEXT_PUBLIC_GA_MEASUREMENT_ID)
                    ENV_VARS="$ENV_VARS,$key=$value"
                    ;;
            esac
        done < <(grep -v '^#' .env.local | grep -v '^$')
    fi
    
    # Override NEXTAUTH_URL and NEXT_PUBLIC_APP_URL with service URL
    ENV_VARS=$(echo "$ENV_VARS" | sed "s|NEXTAUTH_URL=[^,]*|NEXTAUTH_URL=$SERVICE_URL|g")
    ENV_VARS=$(echo "$ENV_VARS" | sed "s|NEXT_PUBLIC_APP_URL=[^,]*|NEXT_PUBLIC_APP_URL=$SERVICE_URL|g")
    
    # If not set, add them
    if [[ ! "$ENV_VARS" =~ NEXTAUTH_URL ]]; then
        ENV_VARS="$ENV_VARS,NEXTAUTH_URL=$SERVICE_URL"
    fi
    if [[ ! "$ENV_VARS" =~ NEXT_PUBLIC_APP_URL ]]; then
        ENV_VARS="$ENV_VARS,NEXT_PUBLIC_APP_URL=$SERVICE_URL"
    fi
    
    # Add SSO_AUTH_URL if not already set
    if [[ ! "$ENV_VARS" =~ SSO_AUTH_URL ]]; then
        ENV_VARS="$ENV_VARS,SSO_AUTH_URL=https://auth.saveaday.ai"
    fi
    
    print_status "Deploying with environment variables..."
    print_warning "Note: Sensitive values should be set via Cloud Run Console or Secret Manager"
    
    # Deploy to Cloud Run - use --set-env-vars to set the specified vars
    # Then update Firebase credentials separately to preserve them
    gcloud run deploy $SERVICE_NAME \
        --image $IMAGE_NAME \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --min-instances 0 \
        --max-instances 10 \
        --memory 1Gi \
        --cpu 1 \
        --timeout 300 \
        --concurrency 80 \
        --set-env-vars "$ENV_VARS"
    
    # Update Firebase credentials and NEXTAUTH_SECRET separately to preserve them
    if [ -f "../creds/dvizfb-314a185c77ef.json" ]; then
        print_status "Updating Firebase credentials from creds file..."
        FIREBASE_PRIVATE_KEY=$(node -e "const creds = require('../creds/dvizfb-314a185c77ef.json'); console.log(creds.private_key.replace(/\n/g, '\\\\n'))")
        
        # Get existing NEXTAUTH_SECRET or generate a new one
        EXISTING_SECRET=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(spec.template.spec.containers[0].env)" | grep -o "NEXTAUTH_SECRET[^,}]*" | cut -d'=' -f2 | tr -d "'\"}" || echo "")
        if [ -z "$EXISTING_SECRET" ]; then
            print_status "Generating new NEXTAUTH_SECRET..."
            NEXTAUTH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
        else
            NEXTAUTH_SECRET="$EXISTING_SECRET"
        fi
        
        gcloud run services update $SERVICE_NAME \
            --region $REGION \
            --update-env-vars "FIREBASE_PROJECT_ID=dvizfb,FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@dvizfb.iam.gserviceaccount.com,FIREBASE_PRIVATE_KEY=$FIREBASE_PRIVATE_KEY,NEXTAUTH_SECRET=$NEXTAUTH_SECRET" \
            --quiet
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Deployment completed successfully"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Wait a moment for the service to be ready
    sleep 5
    
    # Test the deployed service
    print_status "Testing deployed service at $SERVICE_URL"
    
    # Test main page
    if curl -f $SERVICE_URL/ >/dev/null 2>&1; then
        print_success "Deployed main page is accessible"
    else
        print_warning "Deployed main page test failed"
    fi
    
    # Test register page
    if curl -f $SERVICE_URL/register >/dev/null 2>&1; then
        print_success "Deployed register page is accessible"
    else
        print_warning "Deployed register page test failed"
    fi
    
    print_success "Deployment testing completed"
}

# Function to show service information
show_service_info() {
    print_status "Service Information:"
    echo "  Service URL: $SERVICE_URL"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Service Name: $SERVICE_NAME"
    echo "  Image: $IMAGE_NAME"
    
    print_status "Getting service details..."
    gcloud run services describe $SERVICE_NAME --region $REGION --format="table(metadata.name,status.url,spec.template.spec.containers[0].image)"
}

# Main execution
main() {
    echo "=========================================="
    echo "  LeadForm Platform Cloud Run Deployment"
    echo "=========================================="
    echo
    
    # Parse command line arguments
    SKIP_LOCAL_TEST=false  # Test by default to ensure quality
    SKIP_DEPLOYMENT_TEST=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-local-test)
                SKIP_LOCAL_TEST=true
                shift
                ;;
            --skip-deployment-test)
                SKIP_DEPLOYMENT_TEST=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --skip-local-test        Skip local Docker testing"
                echo "  --skip-deployment-test   Skip deployment testing"
                echo "  --help                   Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Execute deployment steps
    check_prerequisites
    enable_apis
    build_local
    test_local
    push_to_gcr
    deploy_to_cloud_run
    
    if [ "$SKIP_DEPLOYMENT_TEST" = false ]; then
        test_deployment
    else
        print_warning "Skipping deployment testing"
    fi
    
    show_service_info
    
    echo
    print_success "Deployment completed successfully! 🎉"
    echo "Your application is available at: $SERVICE_URL"
    echo
    print_warning "⚠️  Important: Update environment variables in Cloud Run Console if needed:"
    echo "  1. Go to Cloud Run → $SERVICE_NAME → Edit & Deploy New Revision"
    echo "  2. Set Variables & Secrets section"
    echo "  3. Ensure all required Firebase and auth credentials are set"
}

# Run main function
main "$@"
