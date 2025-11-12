#!/bin/bash
# ~/eks-project/scripts/build-and-push.sh

set -e

IMAGE_NAME="petclinic"
ECR_REPO="010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
REGION="ap-northeast-2"
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="11fa85685821b2ca7eafcc59727fe06908"
JENKINS_JOB="petclinic-deploy"

# 자동 버전 생성
TAG="v$(date +%Y%m%d-%H%M%S)"

echo "=== Building: ${TAG} ==="
cd $(dirname $0)/../docker/was
docker build -t ${IMAGE_NAME}:${TAG} .

echo "=== Pushing to ECR ==="
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

docker tag ${IMAGE_NAME}:${TAG} ${ECR_REPO}/${IMAGE_NAME}:${TAG}
docker push ${ECR_REPO}/${IMAGE_NAME}:${TAG}

echo "✅ Image pushed: ${TAG}"

echo "=== Triggering Jenkins ==="
CRUMB=$(curl -s -u ${JENKINS_USER}:${JENKINS_TOKEN} \
  "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "${CRUMB}" \
  "${JENKINS_URL}/job/${JENKINS_JOB}/build" \
  --user ${JENKINS_USER}:${JENKINS_TOKEN})

if [ "$RESPONSE" -eq 201 ]; then
  echo "✅ Jenkins triggered!"
else
  echo "❌ Jenkins trigger failed (HTTP ${RESPONSE})"
  exit 1
fi

echo ""
echo "🚀 Done! Jenkins will deploy ${TAG}"
