#!/bin/bash
# Setup script for Terraform remote state backend
# Run this ONCE before first Jenkins deployment

set -e

BUCKET_NAME="student-event-terraform-state"
DYNAMODB_TABLE="student-event-terraform-locks"
REGION="us-east-1"

echo "================================"
echo "Setting up Terraform Remote State"
echo "================================"
echo ""
echo "This creates:"
echo "  - S3 bucket: ${BUCKET_NAME}"
echo "  - DynamoDB table: ${DYNAMODB_TABLE}"
echo ""

# Check if bucket already exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket..."
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region ${REGION} \
        --create-bucket-configuration LocationConstraint=${REGION} 2>/dev/null || \
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region ${REGION}
    
    echo "Enabling bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    echo "Enabling bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket ${BUCKET_NAME} \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    echo "✓ S3 bucket created and configured"
else
    echo "✓ S3 bucket already exists"
fi

# Check if DynamoDB table exists
if ! aws dynamodb describe-table --table-name ${DYNAMODB_TABLE} --region ${REGION} >/dev/null 2>&1; then
    echo "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name ${DYNAMODB_TABLE} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ${REGION}
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name ${DYNAMODB_TABLE} --region ${REGION}
    
    echo "✓ DynamoDB table created"
else
    echo "✓ DynamoDB table already exists"
fi

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Remote state backend is ready."
echo "Next steps:"
echo "  1. Commit provider.tf changes to Git"
echo "  2. Push to GitHub"
echo "  3. Jenkins will now reuse existing infrastructure"
echo ""
echo "Benefits:"
echo "  ✓ Same EC2 instance reused across Jenkins runs"
echo "  ✓ Same Elastic IP maintained"
echo "  ✓ Database data persists"
echo "  ✓ Only Docker images updated on each deployment"
echo ""
