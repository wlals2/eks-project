#!/bin/bash

set -e

IMAGE_NAME="petclinic"
ECR_REPO="010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
REGION="ap-northeast-2"
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="1141e33d444cfed26034f7df7299e78b20"
JENKINS_JOB="petclinic-cicd"

read -p "Enter image tag (e.g., v1.0.1): " TAG

echo "=== Building Docker image ==="
cd $(dirname $0)/../docker/was
docker build -t ${IMAGE_NAME}:${TAG} .

echo "=== ECR Login ==="
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

echo "=== Tagging ==="
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REPO}/${IMAGE_NAME}:${TAG}

echo "=== Pushing to ECR ==="
docker push ${ECR_REPO}/${IMAGE_NAME}:${TAG}

echo "✅ Image pushed: ${ECR_REPO}/${IMAGE_NAME}:${TAG}"

echo ""
echo "=== Getting Jenkins Crumb ==="
CRUMB=$(curl -s -u ${JENKINS_USER}:${JENKINS_TOKEN} \
  "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

echo "=== Triggering Jenkins Job ==="
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "${CRUMB}" \
  "${JENKINS_URL}/job/${JENKINS_JOB}/buildWithParameters?IMAGE_TAG=${TAG}" \
  --user ${JENKINS_USER}:${JENKINS_TOKEN})

if [ "$RESPONSE" -eq 201 ]; then
  echo "✅ Jenkins job triggered successfully!"
  echo "   Job: ${JENKINS_URL}/job/${JENKINS_JOB}"
  echo "   Image Tag: ${TAG}"
else
  echo "❌ Failed to trigger Jenkins (HTTP ${RESPONSE})"
  exit 1
fi

echo ""
echo "🚀 Complete! ArgoCD will sync in ~3 minutes."
