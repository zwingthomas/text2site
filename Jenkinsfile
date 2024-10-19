pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'destroy'], description: 'Select action to perform')
        choice(name: 'CLOUD_PROVIDER', choices: ['aws', 'gcp', 'azure', 'all'], description: 'Select cloud provider(s)')
    }

    environment {
        // Common environment variables
        DOCKER_IMAGE_NAME   = 'hello-world-app'
        DOCKER_IMAGE_TAG    = "${env.BUILD_NUMBER}"
        twilio_auth_token   = credentials('twilio-auth-token')
        APPLICATION_URL     = 'https://your-common-domain.com' // Replace with your actual domain
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/zwingthomas/Text2Site.git'
            }
        }

        // Only build and push Docker image if the action is 'deploy'
        stage('Build Docker Image') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Building Docker Image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                    try {
                        sh """
                        docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ./src
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

        stage('Push to Container Registries') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    def providers = []
                    if (params.CLOUD_PROVIDER == 'all') {
                        providers = ['aws', 'gcp', 'azure']
                    } else {
                        providers = [params.CLOUD_PROVIDER]
                    }

                    for (provider in providers) {
                        if (provider == 'aws') {
                            echo "Pushing Docker Image to AWS ECR..."
                            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                                sh """
                                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 354923279633.dkr.ecr.us-east-1.amazonaws.com
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} 354923279633.dkr.ecr.us-east-1.amazonaws.com/hello-world-repo:${DOCKER_IMAGE_TAG}
                                docker push 354923279633.dkr.ecr.us-east-1.amazonaws.com/hello-world-repo:${DOCKER_IMAGE_TAG}
                                """
                            }
                        } else if (provider == 'gcp') {
                            echo "Pushing Docker Image to GCP Container Registry..."
                            withCredentials([file(credentialsId: 'gcp-credentials-file', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                                sh """
                                gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
                                gcloud auth configure-docker
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} gcr.io/your-project-id/hello-world-repo:${DOCKER_IMAGE_TAG}
                                docker push gcr.io/your-project-id/hello-world-repo:${DOCKER_IMAGE_TAG}
                                """
                            }
                        } else if (provider == 'azure') {
                            echo "Pushing Docker Image to Azure Container Registry..."
                            withCredentials([usernamePassword(credentialsId: 'azure-acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
                                sh """
                                docker login yourregistry.azurecr.io -u $ACR_USERNAME -p $ACR_PASSWORD
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} yourregistry.azurecr.io/hello-world-repo:${DOCKER_IMAGE_TAG}
                                docker push yourregistry.azurecr.io/hello-world-repo:${DOCKER_IMAGE_TAG}
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Init and Apply/Destroy') {
            steps {
                script {
                    def providers = []
                    if (params.CLOUD_PROVIDER == 'all') {
                        providers = ['aws', 'gcp', 'azure']
                    } else {
                        providers = [params.CLOUD_PROVIDER]
                    }

                    for (provider in providers) {
                        dir("terraform-${provider.toUpperCase()}") {
                            if (provider == 'aws') {
                                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for AWS..."
                                        sh """
                                        terraform apply -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image_tag=${DOCKER_IMAGE_TAG}"
                                        """
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying AWS resources..."
                                        sh "terraform destroy -auto-approve"
                                    }
                                }
                            } else if (provider == 'gcp') {
                                withCredentials([file(credentialsId: 'gcp-credentials-file', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for GCP..."
                                        sh """
                                        terraform apply -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image_tag=${DOCKER_IMAGE_TAG}"
                                        """
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying GCP resources..."
                                        sh "terraform destroy -auto-approve"
                                    }
                                }
                            } else if (provider == 'azure') {
                                withCredentials([
                                    string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                                    string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                                    string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID'),
                                    string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for Azure..."
                                        sh """
                                        terraform apply -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image_tag=${DOCKER_IMAGE_TAG}"
                                        """
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying Azure resources..."
                                        sh "terraform destroy -auto-approve"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Only set up the global load balancer if deploying to all providers
        stage('Set Up Global Load Balancer') {
            when {
                allOf {
                    expression { params.ACTION == 'deploy' }
                    expression { params.CLOUD_PROVIDER == 'all' }
                }
            }
            steps {
                script {
                    echo "Setting up global load balancer and DNS..."
                    // Use a DNS provider or global load balancer that supports multi-cloud endpoints
                    // This example assumes using AWS Route 53 as the DNS provider
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        // Collect the endpoints from each provider
                        def awsEndpoint = sh(
                            script: "terraform output -state=terraform-AWS/terraform.tfstate load_balancer_dns",
                            returnStdout: true
                        ).trim()
                        def gcpEndpoint = sh(
                            script: "terraform output -state=terraform-GCP/terraform.tfstate load_balancer_ip",
                            returnStdout: true
                        ).trim()
                        def azureEndpoint = sh(
                            script: "terraform output -state=terraform-AZURE/terraform.tfstate load_balancer_ip",
                            returnStdout: true
                        ).trim()

                        // Update Route 53 DNS records to point to the endpoints
                        // Replace 'YOUR_HOSTED_ZONE_ID' and 'your-common-domain.com' with your actual values
                        sh """
                        aws route53 change-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID --change-batch '{
                            "Comment": "Update record to add multi-cloud endpoints",
                            "Changes": [
                                {
                                    "Action": "UPSERT",
                                    "ResourceRecordSet": {
                                        "Name": "your-common-domain.com.",
                                        "Type": "A",
                                        "TTL": 60,
                                        "ResourceRecords": [
                                            {"Value": "${awsEndpoint}"},
                                            {"Value": "${gcpEndpoint}"},
                                            {"Value": "${azureEndpoint}"}
                                        ]
                                    }
                                }
                            ]
                        }'
                        """
                    }
                }
            }
        }

        // Only perform verification if deploying
        stage('Verification') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    // Wait for DNS propagation
                    sleep(time: 120, unit: 'SECONDS')

                    echo "Verifying deployment at ${APPLICATION_URL}"

                    // Check HTTP status code
                    def http_status = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' ${APPLICATION_URL}",
                        returnStdout: true
                    ).trim()

                    if (http_status == '200') {
                        echo "Deployment verification succeeded. HTTP status code is 200."
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
