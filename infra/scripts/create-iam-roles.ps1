param([string]$Environment = "staging")

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)

Write-Host "Creating IAM roles for khasm-$Environment..."

# RDS service-linked role
aws iam create-service-linked-role --aws-service-name rds.amazonaws.com 2>$null
if ($?) { Write-Host "  RDS service-linked role created" } else { Write-Host "  RDS service-linked role already exists" }

# ECS Execution Role
$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": { "Service": "ecs-tasks.amazonaws.com" }
  }]
}
"@

aws iam create-role `
  --role-name "khasm-$Environment-ecs-execution" `
  --assume-role-policy-document $trustPolicy `
  --description "ECS execution role for Khasm $Environment" 2>$null
if ($?) { Write-Host "  Created khasm-$Environment-ecs-execution" } else { Write-Host "  khasm-$Environment-ecs-execution already exists" }

aws iam attach-role-policy `
  --role-name "khasm-$Environment-ecs-execution" `
  --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

$extraPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:GetDownloadUrlForLayer","ecr:BatchGetImage","ecr:BatchCheckLayerAvailability"],
      "Resource": "arn:aws:ecr:$AWS_REGION`:$ACCOUNT_ID:repository/khasm-$Environment-backend"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogStream","logs:PutLogEvents"],
      "Resource": "arn:aws:logs:$AWS_REGION`:$ACCOUNT_ID:log-group:/ecs/khasm-$Environment-backend:*"
    }
  ]
}
"@

aws iam put-role-policy `
  --role-name "khasm-$Environment-ecs-execution" `
  --policy-name "khasm-$Environment-ecs-execution-extra" `
  --policy-document $extraPolicy

# ECS Task Role
$taskTrustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": { "Service": "ecs-tasks.amazonaws.com" }
  }]
}
"@

aws iam create-role `
  --role-name "khasm-$Environment-ecs-task" `
  --assume-role-policy-document $taskTrustPolicy `
  --description "ECS task role for Khasm $Environment" 2>$null
if ($?) { Write-Host "  Created khasm-$Environment-ecs-task" } else { Write-Host "  khasm-$Environment-ecs-task already exists" }

$githubActionsPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:GetDownloadUrlForLayer","ecr:BatchGetImage","ecr:BatchCheckLayerAvailability","ecr:PutImage","ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload"],
      "Resource": "arn:aws:ecr:$AWS_REGION`:$ACCOUNT_ID:repository/khasm-$Environment-backend"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject","s3:GetObject","s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::khasm-$Environment-flutter-web",
        "arn:aws:s3:::khasm-$Environment-flutter-web/*",
        "arn:aws:s3:::khasm-$Environment-nextjs",
        "arn:aws:s3:::khasm-$Environment-nextjs/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "*"
    }
  ]
}
"@

aws iam put-role-policy `
  --role-name "khasm-$Environment-ecs-task" `
  --policy-name "khasm-$Environment-github-actions" `
  --policy-document $githubActionsPolicy

Write-Host "All IAM roles created for khasm-$Environment"
