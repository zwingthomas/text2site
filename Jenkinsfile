pipeline {
    agent any

    parameters {
        choice(name: 'CLOUD_PROVIDER', choices: ['aws', 'gcp', 'azure'], description: 'Select cloud provider')
    }

    environment {
        CLOUD_PROVIDER = "${params.CLOUD_PROVIDER}"

        // Common environment variables
        DOCKER_IMAGE_NAME           = 'hello-world-app'
        DOCKER_IMAGE_TAG            = "${env.BUILD_NUMBER}"
        twilio_auth_token           = credentials('twilio-auth-token')
        APPLICATION_URL             = 'http://text18449410220anything-zwinger.com'

        // Cloud-specific environment variables (will be set in 'Setup Environment' stage)
        CLOUD_REGION                = ''
        CONTAINER_REGISTRY_URI      = ''
        CLUSTER_NAME                = ''
        SERVICE_NAME                = ''
        TASK_EXECUTION_ROLE_ARN     = ''
        TASK_ROLE_ARN               = ''
    }

    stages {
        stage('Setup Environment') {
            steps {
                script {
                    if (CLOUD_PROVIDER == 'aws') {
                        env.CLOUD_REGION                = 'us-east-1'
                        env.CONTAINER_REGISTRY_URI      = '354923279633.dkr.ecr.us-east-1.amazonaws.com/hello-world-repo'
                        env.CLUSTER_NAME                = 'hello-world-app-cluster'
                        env.SERVICE_NAME                = 'hello-world-app-service'
                        env.TASK_EXECUTION_ROLE_ARN     = 'arn:aws:iam::354923279633:role/hello-world-app-ecs-task-execution-role'
                        env.TASK_ROLE_ARN               = 'arn:aws:iam::354923279633:role/hello-world-app-task-role'
                    } else if (CLOUD_PROVIDER == 'gcp') {
                        env.CLOUD_REGION                = 'us-central1'
                        env.CONTAINER_REGISTRY_URI      = 'gcr.io/your-project-id/hello-world-repo'
                        env.CLUSTER_NAME                = 'hello-world-app-cluster-gcp'
                        env.SERVICE_NAME                = 'hello-world-app-service-gcp'
                        // Set GCP-specific roles or service accounts if needed
                    } else if (CLOUD_PROVIDER == 'azure') {
                        env.CLOUD_REGION                = 'eastus'
                        env.CONTAINER_REGISTRY_URI      = 'yourregistry.azurecr.io/hello-world-repo'
                        env.CLUSTER_NAME                = 'hello-world-app-cluster-azure'
                        env.SERVICE_NAME                = 'hello-world-app-service-azure'
                        // Set Azure-specific roles or service principals if needed
                    } else {
                        error "Unsupported cloud provider: ${CLOUD_PROVIDER}"
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/zwingthomas/Text2Site.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker Image: ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}"
                    try {
                        sh """
                        docker build -t ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG} ./src
                        """
                        echo "Docker Image built successfully."
                    } catch (Exception e) {
                        echo "Docker build failed: ${e}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        stage('Push to Container Registry') {
            steps {
                script {
                    if (CLOUD_PROVIDER == 'aws') {
                        echo "Logging in to AWS ECR..."
                        sh '''
                        aws ecr get-login-password --region ${CLOUD_REGION} | docker login --username AWS --password-stdin ${CONTAINER_REGISTRY_URI}
                        if [ $? -ne 0 ]; then
                            echo "Failed to log in to ECR"
                            exit 1
                        fi
                        '''
                        echo "Pushing Docker Image: ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}"
                        sh """
                        docker push ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}
                        """
                    } else if (CLOUD_PROVIDER == 'gcp') {
                        echo "Logging in to GCP Container Registry..."
                        sh '''
                        gcloud auth configure-docker
                        '''
                        echo "Pushing Docker Image: ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}"
                        sh """
                        docker push ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}
                        """
                    } else if (CLOUD_PROVIDER == 'azure') {
                        echo "Logging in to Azure Container Registry..."
                        sh '''
                        az acr login --name yourregistry
                        '''
                        echo "Pushing Docker Image: ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}"
                        sh """
                        docker push ${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Terraform Init and Apply') {
            steps {
                dir("terraform-${CLOUD_PROVIDER.toUpperCase()}") {
                    sh '''
                    terraform init
                    terraform apply -auto-approve -var="twilio_auth_token=${twilio_auth_token}"
                    '''
                }
            }
        }

        // Clean up resources before terraform destroy (if necessary)
        stage('Cleanup Resources') {
            steps {
                script {
                    if (CLOUD_PROVIDER == 'aws') {
                        echo "Cleaning up AWS ECS services and tasks"
                        sh """
                        aws ecs update-service \
                            --cluster ${CLUSTER_NAME} \
                            --service ${SERVICE_NAME} \
                            --desired-count 0
                        aws ecs wait services-stable --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}
                        aws ecs delete-service \
                            --cluster ${CLUSTER_NAME} \
                            --service ${SERVICE_NAME} \
                            --force
                        aws ecs delete-cluster --cluster ${CLUSTER_NAME}
                        """
                    } else if (CLOUD_PROVIDER == 'gcp') {
                        echo "Cleaning up GCP resources"
                        // Add GCP cleanup commands here
                    } else if (CLOUD_PROVIDER == 'azure') {
                        echo "Cleaning up Azure resources"
                        // Add Azure cleanup commands here
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    if (CLOUD_PROVIDER == 'aws') {
                        // Register a new task definition with the new image
                        def taskDefinition = sh(
                            script: """
                            aws ecs register-task-definition \
                                --family hello-world-task \
                                --task-role-arn ${TASK_ROLE_ARN} \
                                --execution-role-arn ${TASK_EXECUTION_ROLE_ARN} \
                                --network-mode awsvpc \
                                --requires-compatibilities FARGATE \
                                --cpu "256" \
                                --memory "512" \
                                --container-definitions '[
                                    {
                                        "name": "app",
                                        "image": "${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}",
                                        "essential": true,
                                        "portMappings": [
                                            {
                                                "containerPort": 5000,
                                                "protocol": "tcp"
                                            }
                                        ],
                                        "environment": [
                                            {
                                                "name": "twilio_auth_token",
                                                "value": "${twilio_auth_token}"
                                            }
                                        ],
                                        "logConfiguration": {
                                            "logDriver": "awslogs",
                                            "options": {
                                                "awslogs-group": "/ecs/hello-world-app",
                                                "awslogs-region": "${CLOUD_REGION}",
                                                "awslogs-stream-prefix": "ecs"
                                            }
                                        }
                                    }
                                ]'
                            """,
                            returnStdout: true
                        ).trim()
                        
                        // Extract task definition ARN
                        def taskDefArn = readJSON(text: taskDefinition).taskDefinition.taskDefinitionArn
                        
                        // Update ECS service to use the new task definition
                        sh """
                        aws ecs update-service \
                            --cluster ${CLUSTER_NAME} \
                            --service ${SERVICE_NAME} \
                            --task-definition ${taskDefArn} \
                            --force-new-deployment
                        """
                    } else if (CLOUD_PROVIDER == 'gcp') {
                        withCredentials([
                            file(credentialsId: 'gcp-credentials-file', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                                dir("terraform-${CLOUD_PROVIDER.toUpperCase()}") {
                                    sh """
                                    terraform init
                                    terraform apply -auto-approve \
                                        -var="twilio_auth_token=${twilio_auth_token}" \
                                        -var="docker_image=${CONTAINER_REGISTRY_URI}:${DOCKER_IMAGE_TAG}" \
                                        -var="YOUR_TRUSTED_IP_RANGE=${YOUR_TRUSTED_IP_RANGE}" \
                                        -var="enable_logging=true" \
                                        -var="enable_monitoring=true"
                                    """
                                }
                            }
                    } else if (CLOUD_PROVIDER == 'azure') {
                        // Deploy to Azure (e.g., AKS or App Service)
                        echo "Deploying to Azure..."
                        sh """
                        # Add Azure deployment commands here
                        """
                    }
                }
            }
        }

        stage('Verification') {
            steps {
                script {
                    // Wait for the service to stabilize
                    sleep(time: 30, unit: 'SECONDS')

                    // Check HTTP status code
                    def http_status = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' ${APPLICATION_URL}",
                        returnStdout: true
                    ).trim()

                    if (http_status == '200') {
                        echo 'HTTP status code is 200.'
                    } else {
                        error "Deployment verification failed. HTTP status code: ${http_status}"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
