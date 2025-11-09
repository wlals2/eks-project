pipeline {
  agent any
  
  environment {
    ECR_REPO = "010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
    IMAGE_NAME = "petclinic"
    REGION = "ap-northeast-2"
  }
  
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'github-token',
            url: 'https://github.com/wlals2/eks-project.git'
      }
    }
    
    stage('Build Docker Image') {
      steps {
        script {
          sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} docker/was/"
        }
      }
    }
    
    stage('Push to ECR') {
      steps {
        script {
          withAWS(credentials: 'aws-ecr', region: "${REGION}") {
            sh """
              aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
              docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${ECR_REPO}/${IMAGE_NAME}:${BUILD_NUMBER}
              docker push ${ECR_REPO}/${IMAGE_NAME}:${BUILD_NUMBER}
            """
          }
        }
      }
    }
    
    stage('Update K8s Manifest') {
      steps {
        script {
          sh """
            sed -i 's|image: .*petclinic:.*|image: ${ECR_REPO}/${IMAGE_NAME}:${BUILD_NUMBER}|' k8s/was-deployment.yaml
            git config user.name "Jenkins"
            git config user.email "jenkins@eks.local"
            git add k8s/was-deployment.yaml
            git commit -m "Update petclinic image to build ${BUILD_NUMBER}"
            git push https://${GITHUB_TOKEN}@github.com/wlals2/eks-project.git main
          """
        }
      }
    }
  }
  
  post {
    success {
      echo "Pipeline succeeded!"
    }
    failure {
      echo "Pipeline failed!"
    }
  }
}
