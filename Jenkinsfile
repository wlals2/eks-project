pipeline {
  agent any
  
  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Image tag')
  }
  
  environment {
    ECR_REPO = "010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
    IMAGE_NAME = "petclinic"
  }
  
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'github-cred',
            url: 'https://github.com/wlals2/eks-project.git'
      }
    }
    
    stage('Update Manifest') {
      steps {
        sh """
          sed -i "s|image: ${ECR_REPO}/${IMAGE_NAME}:.*|image: ${ECR_REPO}/${IMAGE_NAME}:${params.IMAGE_TAG}|" k8s/was-deployment.yaml
          cat k8s/was-deployment.yaml | grep image:
        """
      }
    }
    
    stage('Push to Git') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh """
            git config user.name "jenkins"
            git config user.email "jenkins@example.com"
            git checkout main
            git pull origin main
            git add k8s/was-deployment.yaml
            git commit -m "Update image to ${params.IMAGE_TAG}" || true
            git push https://${GIT_USER}:${GIT_PASS}@github.com/wlals2/eks-project.git main
          """
        }
      }
    }
  }
  
  post {
    success {
      echo "✅ Deployed: ${params.IMAGE_TAG}"
    }
  }
}
