pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 9999999
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sleep
    args:
    - 9999999
  volumes:
  - name: kaniko-secret
    secret:
      secretName: ecr-credentials
      items:
      - key: .dockerconfigjson
        path: config.json
"""
    }
  }
  
  environment {
    ECR_REPO = "010068699561.dkr.ecr.ap-northeast-2.amazonaws.com"
    IMAGE_NAME = "petclinic"
    REGION = "ap-northeast-2"
  }
  
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'github-cred',
            url: 'https://github.com/wlals2/eks-project.git'
      }
    }
    
    stage('Build with Kaniko') {
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \
              --context=\${WORKSPACE}/docker/was \
              --dockerfile=\${WORKSPACE}/docker/was/Dockerfile \
              --destination=\${ECR_REPO}/\${IMAGE_NAME}:\${BUILD_NUMBER}
          """
        }
      }
    }
    
    stage('Update K8s Manifest') {
      steps {
        container('kubectl') {
          sh """
            sed -i 's|image: .*petclinic:.*|image: \${ECR_REPO}/\${IMAGE_NAME}:\${BUILD_NUMBER}|' k8s/was-deployment.yaml
          """
        }
        
        withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
          sh """
            git config user.name "Jenkins"
            git config user.email "jenkins@eks.local"
            git add k8s/was-deployment.yaml
            git commit -m "Update petclinic image to build \${BUILD_NUMBER}"
            git push https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/wlals2/eks-project.git main
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
