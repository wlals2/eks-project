#!/bin/bash

set -e

IMAGE_NAME="petclinic"
ECR_REPO="010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
REGION="ap-northeast-2"
JENKINS_URL="http://localhost:8080"  # SSH 터널링 사용 시
JENKINS_USER="admin"
JENKINS_TOKEN="11436dccf7ff27bd32c8b35d2e73a7dcb8"  # Jenkins에서 생성한 API 토큰
JENKINS_JOB="petclinic-deploy"  # Jenkins Job 이름

# 버전 입력
read -p "Enter image tag (e.g., v1.0.1): " TAG

echo "=== Building Docker image ==="
cd /home/ec2-user/docker-dev/petclinic_btc
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
