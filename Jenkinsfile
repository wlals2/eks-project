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
          echo "Latest: ${env.IMAGE_TAG}"
        }
      }
    }
    
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    
    stage('Update Manifest') {
      steps {
        sh """
          sed -i "s|image: ${ECR_REPO}/${IMAGE_NAME}:.*|image: ${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}|" k8s/was-deployment.yaml
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
            git add k8s/was-deployment.yaml
            git commit -m "Update image to ${IMAGE_TAG}" || true
            git push https://${GIT_USER}:${GIT_PASS}@github.com/wlals2/eks-project.git main
          """
        }
      }
    }
  }
  
  post {
    success {
      echo "Deployed: ${env.IMAGE_TAG}"
    }
  }
}
