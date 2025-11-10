pipeline {
  agent any
  
  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'ECR image tag')
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
          sed -i 's|image: ${ECR_REPO}/${IMAGE_NAME}:.*|image: ${ECR_REPO}/${IMAGE_NAME}:${params.IMAGE_TAG}|' k8s/was-deployment.yaml
          echo "Updated image to: ${ECR_REPO}/${IMAGE_NAME}:${params.IMAGE_TAG}"
          cat k8s/was-deployment.yaml | grep image:
        """
      }
    }
    
    stage('Push to Git') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
          sh """
            git config user.name "Jenkins"
            git config user.email "jenkins@local"
            git add k8s/was-deployment.yaml
            git commit -m "Update image to ${params.IMAGE_TAG}"
            git push https://\${USER}:\${PASS}@github.com/wlals2/eks-project.git main
          """
        }
      }
    }
  }
  
  post {
    success {
      echo "✅ Manifest updated! ArgoCD will sync."
    }
    failure {
      echo "❌ Failed!"
    }
  }
}
