#!/bin/bash

set -e

IMAGE_NAME="petclinic"
ECR_REPO="010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
REGION="ap-northeast-2"
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="1136459d2253d5692a367b6d0d4b1093e9"
JENKINS_JOB="petclinic-deploy"

# 자동 버전 생성
TAG="v$(date +%Y%m%d-%H%M%S)"

echo "=== Building: ${TAG} ==="
cd /home/ec2-user/docker-dev/petclinic_btc
docker build -t ${IMAGE_NAME}:${TAG} .

echo "=== Pushing to ECR ==="
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

docker tag ${IMAGE_NAME}:${TAG} ${ECR_REPO}/${IMAGE_NAME}:${TAG}
docker push ${ECR_REPO}/${IMAGE_NAME}:${TAG}

echo "✅ Image pushed: ${TAG}"

echo "=== Triggering Jenkins with TAG=${TAG} ==="
CRUMB=$(curl -s -u ${JENKINS_USER}:${JENKINS_TOKEN} \
  "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "${CRUMB}" \
  "${JENKINS_URL}/job/${JENKINS_JOB}/buildWithParameters?IMAGE_TAG=${TAG}" \
  --user ${JENKINS_USER}:${JENKINS_TOKEN})

if [ "$RESPONSE" -eq 201 ]; then
  echo "✅ Jenkins triggered with ${TAG}!"
else
  echo "❌ Failed (HTTP ${RESPONSE})"
  exit 1
fi
