#!/bin/bash
# Run this with an admin AWS account to create IAM roles for Khasm staging
# Usage: ./create-iam-roles.sh <environment>
# Example: ./create-iam-roles.sh staging

ENV=${1:-staging}
AWS_REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create RDS service-linked role (required for RDS)
aws iam create-service-linked-role --aws-service-name rds.amazonaws.com 2>/dev/null || echo "RDS role already exists"

# --- ECS Execution Role ---
cat > /tmp/ecs-execution-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": { "Service": "ecs-tasks.amazonaws.com" }
  }]
}
EOF

aws iam create-role \
  --role-name "khasm-${ENV}-ecs-execution" \
  --assume-role-policy-document file:///tmp/ecs-execution-trust-policy.json \
  --description "ECS execution role for Khasm ${ENV}"

aws iam attach-role-policy \
  --role-name "khasm-${ENV}-ecs-execution" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

cat > /tmp/ecs-execution-extra-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:${AWS_REGION}:${ACCOUNT_ID}:repository/khasm-${ENV}-backend"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:${AWS_REGION}:${ACCOUNT_ID}:log-group:/ecs/khasm-${ENV}-backend:*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "khasm-${ENV}-ecs-execution" \
  --policy-name "khasm-${ENV}-ecs-execution-extra" \
  --policy-document file:///tmp/ecs-execution-extra-policy.json

# --- ECS Task Role ---
cat > /tmp/ecs-task-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": { "Service": "ecs-tasks.amazonaws.com" }
  }]
}
EOF

aws iam create-role \
  --role-name "khasm-${ENV}-ecs-task" \
  --assume-role-policy-document file:///tmp/ecs-task-trust-policy.json \
  --description "ECS task role for Khasm ${ENV}"

cat > /tmp/github-actions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability", "ecr:PutImage",
        "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:${AWS_REGION}:${ACCOUNT_ID}:repository/khasm-${ENV}-backend"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::khasm-${ENV}-flutter-web",
        "arn:aws:s3:::khasm-${ENV}-flutter-web/*",
        "arn:aws:s3:::khasm-${ENV}-nextjs",
        "arn:aws:s3:::khasm-${ENV}-nextjs/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "khasm-${ENV}-ecs-task" \
  --policy-name "khasm-${ENV}-github-actions" \
  --policy-document file:///tmp/github-actions-policy.json

echo "All IAM roles created for khasm-${ENV}"
