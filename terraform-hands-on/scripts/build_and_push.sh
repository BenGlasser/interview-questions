#!/bin/bash
set -e

# Build and push container to ECR for the Terraform challenge
# This script should be run from the scripts/ directory

echo "🐳 Building and pushing container to ECR..."

# Check if we're in the right directory
if [[ ! -f "../app/Dockerfile" ]]; then
    echo "❌ Error: Please run this script from the scripts/ directory"
    echo "   Expected to find ../app/Dockerfile"
    exit 1
fi

# Check if terraform outputs are available
if [[ ! -d "../infra" ]]; then
    echo "❌ Error: Terraform infrastructure not found"
    echo "   Please run 'terraform apply' in the infra/ directory first"
    exit 1
fi

# Get ECR repository URL from Terraform output
echo "📡 Getting ECR repository URL from Terraform..."
cd ../infra
ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

if [[ -z "$ECR_REPO" ]]; then
    echo "❌ Error: Could not get ECR repository URL from Terraform outputs"
    echo "   Make sure 'terraform apply' has been run successfully"
    exit 1
fi

echo "📦 ECR Repository: $ECR_REPO"
echo "🌍 AWS Region: $REGION"

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REPO"

# Build the Docker image
echo "🏗️  Building Docker image..."
cd ../app
docker build -t terraform-challenge-app .

# Tag the image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag terraform-challenge-app:latest "$ECR_REPO:latest"

# Push to ECR
echo "⬆️  Pushing image to ECR..."
docker push "$ECR_REPO:latest"

echo "✅ Successfully built and pushed container!"
echo ""
echo "📋 Next steps:"
echo "   1. Wait for App Runner to detect and deploy the new image (~5-10 minutes)"
echo "   2. Check App Runner service status:"
echo "      aws apprunner describe-service --service-arn \$(cd ../infra && terraform output -raw app_runner_service_arn)"
echo "   3. Test the application:"
echo "      curl \$(cd ../infra && terraform output -raw app_runner_url)/health"
echo ""
echo "🔍 If the health check fails, start troubleshooting with the /health endpoint!"
echo "   The Redis connection error is the challenge you need to solve."

# Optional: trigger App Runner deployment
read -p "🚀 Would you like to trigger an immediate App Runner deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⚡ Triggering App Runner deployment..."
    cd ../infra
    SERVICE_ARN=$(terraform output -raw app_runner_service_arn)
    aws apprunner start-deployment --service-arn "$SERVICE_ARN"
    echo "✅ Deployment started. Monitor progress in the AWS Console."
else
    echo "⏳ App Runner will automatically detect and deploy the new image within ~10 minutes."
fi