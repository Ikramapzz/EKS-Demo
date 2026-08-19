pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    DOCKERHUB_USER   = 'ikramapzz55'          // TODO: change me
    IMAGE_NAME       = "${DOCKERHUB_USER}/jenkins-eks-demo"
    IMAGE_TAG        = "${env.BUILD_NUMBER}"
    EKS_CLUSTER_NAME = 'my-eks-cluster'                    // TODO: change me
    AWS_REGION       = 'ap-south-1'                         // TODO: change me
    K8S_NAMESPACE    = 'demo'
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
                    url: 'https://github.com/Ikramapzz/EKS-Demo.git'
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('app') {
          sh 'npm ci'
        }
      }
    }

    stage('Test') {
      steps {
        dir('app') {
          sh 'npm test'
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${IMAGE_NAME}:latest
            docker logout
          '''
        }
      }
    }

    stage('Configure kubectl for EKS') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-eks-creds'
        ]]) {
          sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}"
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-eks-creds'
        ]]) {
          sh '''
            kubectl apply -f k8s/namespace.yaml
            sed "s|IMAGE_PLACEHOLDER|${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml > k8s/deployment.rendered.yaml
            kubectl apply -f k8s/deployment.rendered.yaml
            kubectl apply -f k8s/service.yaml
            kubectl rollout status deployment/jenkins-eks-demo -n ${K8S_NAMESPACE} --timeout=120s
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Deployed ${IMAGE_NAME}:${IMAGE_TAG} to EKS cluster ${EKS_CLUSTER_NAME}."
    }
    failure {
      echo 'Pipeline failed. Check the stage logs above.'
    }
    always {
      sh 'docker image prune -f || true'
    }
  }
}
