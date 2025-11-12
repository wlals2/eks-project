pipeline {
  agent any
  
  environment {
    ECR_REPO = "010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
    IMAGE_NAME = "petclinic"
    REGION = "ap-northeast-2"
  }
  
  stages {
    stage('Get Latest Image') {
      steps {
        script {
          env.IMAGE_TAG = sh(
            script: """
              aws ecr describe-images \
                --repository-name ${IMAGE_NAME} \
                --region ${REGION} \
                --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
                --output text
            """,
            returnStdout: true
          ).trim()
          
          echo "📦 Latest: ${env.IMAGE_TAG}"
        }
      }
    }
    
    stage('Update & Push') {
      steps {
        git branch: 'main', credentialsId: 'github-cred', url: 'https://github.com/...'
        
        sh "sed -i 's|image: .*petclinic:.*|image: ${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}|' k8s/was-deployment.yaml"
        
        withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'U', passwordVariable: 'P')]) {
          sh """
            git config user.name jenkins
            git add k8s/was-deployment.yaml
            git commit -m "Deploy ${IMAGE_TAG}"
            git push https://${U}:${P}@github.com/... main
          """
        }
      }
    }
  }
}
```

---

## 🔄 워크플로우
```
1. 개발자: ./scripts/build-and-push.sh 실행
   ↓
2. 스크립트:
   - Docker 빌드 (v20251112-143022)
   - ECR 푸시
   - Jenkins 자동 트리거 ✅
   ↓
3. Jenkins:
   - ECR 최신 이미지 자동 감지
   - YAML 업데이트
   - Git Push
   ↓
4. ArgoCD: 자동 배포
