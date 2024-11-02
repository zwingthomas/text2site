pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'destroy'], description: 'Select action to perform')
        choice(name: 'CLOUD_PROVIDER', choices: ['gcp', 'aws', 'azure', 'all'], description: 'Select cloud provider(s)')
    }

    environment {
        // Common environment variables
        DOCKER_IMAGE_NAME            = 'hello-world-app'
        DOCKER_IMAGE_TAG             = "${env.BUILD_NUMBER}"
        APPLICATION_URL              = 'https://text18449410220anything-zwinger.org'

        // Credentials IDs (these are not the secrets themselves)
        TWILIO_AUTH_TOKEN_CRED_ID    = 'twilio-auth-token'                // Jenkins credentials ID for Twilio Auth Token

        // AWS-specific environment variables
        AWS_REGION                   = 'us-east-1'                        
        AWS_ECR_REPO_NAME            = 'hello-world-app-repo'                 
        AWS_CREDENTIALS_ID           = 'aws-credentials'                  // Jenkins credentials ID for AWS
        AWS_ACCOUNT_ID_CRED_ID       = 'aws-account-id'                   // Jenkins credentials ID for AWS Account ID
        AWS_HOSTED_ZONE_ID_CRED_ID   = 'aws-hosted-zone-id'               // Jenkins credentials ID for AWS Hosted Zone ID
        AWS_DOMAIN_NAME              =  "${APPLICATION_URL}"

        // GCP-specific environment variables
        GCP_PROJECT_ID               = 'gcp-project'                      // Jenkins credentials ID for GCP Project
        GCP_CREDENTIALS_ID           = 'gcp-credentials-file'             // Jenkins credentials ID for GCP Service Account Key

        // Azure-specific environment variables
        AZURE_REGISTRY_NAME          = 'helloworldappregistry.azurecr.io'
        AZURE_ACR_CREDENTIALS_ID     = 'azure-acr-credentials'            // Jenkins credentials ID for Azure ACR
       
        // Azure credentials IDs for Terraform
        AZURE_CLIENT_ID_CRED_ID         = 'azure-client-id'               // Jenkins credentials ID for Azure Client ID
        AZURE_CLIENT_SECRET_CRED_ID     = 'azure-client-secret'           // Jenkins credentials ID for Azure Client Secret
        AZURE_SUBSCRIPTION_ID_CRED_ID   = 'azure-subscription-id'         // Jenkins credentials ID for Azure Subscription ID
        AZURE_TENANT_ID_CRED_ID         = 'azure-tenant-id'               // Jenkins credentials ID for Azure Tenant ID
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
                    def providers = []
                    if (params.CLOUD_PROVIDER == 'all') {
                        providers = ['azure', 'others']
                    } else {
                        providers = [params.CLOUD_PROVIDER]
                    }
                    for (provider in providers) {
                        if (provider == 'azure') {
                            script {
                                echo "Building Docker Image for ARM64: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                                try {
                                    sh """
                                    # Enable QEMU emulation
                                    docker run --privileged --rm tonistiigi/binfmt --install all

                                    # Remove existing builder if it exists
                                    docker buildx rm mybuilder || true

                                    # Create and use a new builder
                                    docker buildx create --use --name mybuilder

                                    # Use the builder
                                    docker buildx use mybuilder

                                    # Build and push the ARM64 image with verbose output
                                    docker buildx build --platform linux/arm64 \
                                        --progress=plain --no-cache \
                                        -t ${env.AZURE_REGISTRY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                                        --push ./src

                                    # Clean up the builder
                                    docker buildx rm mybuilder
                                    """
                                    echo "Docker Image built and pushed successfully."
                                } catch (Exception e) {
                                    echo "Docker build failed with exception: ${e}"
                                    currentBuild.result = 'FAILURE'
                                    throw e
                                }
                            }
                        } else{
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
                            withCredentials([
                                [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID],
                                string(credentialsId: env.AWS_ACCOUNT_ID_CRED_ID, variable: 'AWS_ACCOUNT_ID')
                            ]) {
                                sh """
                                aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.AWS_ECR_REPO_NAME}:${DOCKER_IMAGE_TAG}
                                docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.AWS_ECR_REPO_NAME}:${DOCKER_IMAGE_TAG}
                                """
                            }
                        } else if (provider == 'gcp') {
                            echo "Pushing Docker Image to GCP Container Registry..."
                            
                            // Use withCredentials to retrieve both GCP credentials and GCP project ID
                            withCredentials([file(credentialsId: env.GCP_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                                            string(credentialsId: 'gcp-project', variable: 'GCP_PROJECT_ID')]) {
                                sh """
                                gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                                gcloud config set project ${GCP_PROJECT_ID}
                                gcloud auth configure-docker us-central1-docker.pkg.dev
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                docker push us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                """
                            }
                        } 
                        // else if (provider == 'azure') {
                        //     echo "Pushing Docker Image to Azure Container Registry..."
                        //     withCredentials([usernamePassword(credentialsId: env.AZURE_ACR_CREDENTIALS_ID, usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
                        //         sh """
                        //         docker login ${env.AZURE_REGISTRY_NAME} -u $ACR_USERNAME -p $ACR_PASSWORD
                        //         docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${env.AZURE_REGISTRY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                        //         docker push ${env.AZURE_REGISTRY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                        //         """
                        //     }
                        // }
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
                                withCredentials([
                                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID],
                                    string(credentialsId: env.AWS_ACCOUNT_ID_CRED_ID, variable: 'AWS_ACCOUNT_ID')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for AWS..."
                                        withCredentials([string(credentialsId: env.TWILIO_AUTH_TOKEN_CRED_ID, variable: 'twilio_auth_token')]) {
                                            try {
                                                def result = sh(
                                                    script: """
                                                    terraform apply -auto-approve \
                                                        -var="docker_image_tag=${BUILD_NUMBER}" \
                                                        -var twilio_auth_token=\$twilio_auth_token \
                                                        -var aws_region=${env.AWS_REGION} \
                                                        -var create_ecr_repo=false 2>&1
                                                    """,
                                                    returnStatus: true // Captures exit code only
                                                )

                                                // Log the output and handle errors
                                                if (result != 0) {
                                                    echo "Terraform apply failed with exit code ${result}"
                                                    error "Terraform apply failed"
                                                } else {
                                                    echo "Terraform apply succeeded."
                                                }
                                            } catch (Exception e) {
                                                echo "Terraform apply failed: ${e}"
                                                currentBuild.result = 'FAILURE'
                                                throw e
                                            }
                                        }
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying AWS resources..."
                                        try {
                                            def result = sh(
                                                script: """
                                                terraform destroy -auto-approve \
                                                    -var="docker_image_tag=${BUILD_NUMBER}" \
                                                    -var twilio_auth_token=\$twilio_auth_token \
                                                    -var aws_region=${env.AWS_REGION} \
                                                    -var create_ecr_repo=false 2>&1
                                                """,
                                                returnStatus: true // Captures exit code only
                                            )

                                            // Log the output and handle errors
                                            if (result != 0) {
                                                echo "Terraform destroy failed with exit code ${result}"
                                                error "Terraform destroy failed"
                                            } else {
                                                echo "Terraform destroy succeeded."
                                            }
                                        } catch (Exception e) {
                                            echo "Terraform destroy failed: ${e}"
                                            currentBuild.result = 'FAILURE'
                                            throw e
                                        }
                                    }
                                }
                            } else if (provider == 'gcp') {
                                withCredentials([
                                    file(credentialsId: env.GCP_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                                    string(credentialsId: env.TWILIO_AUTH_TOKEN_CRED_ID, variable: 'twilio_auth_token'),
                                    string(credentialsId: 'gcp-project', variable: 'GCP_PROJECT_ID')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for GCP..."
                                        sh """
                                        terraform apply -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image_tag=us-central1-docker.pkg.dev/${env.GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                            -var="project_id=${env.GCP_PROJECT_ID}" \
                                            -var="credentials_file=${GOOGLE_APPLICATION_CREDENTIALS}"
                                        """
                                        sh "terraform output"
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying GCP resources..."
                                        sh """
                                        terraform destroy -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image_tag=us-central1-docker.pkg.dev/${env.GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                            -var="project_id=${env.GCP_PROJECT_ID}" \
                                            -var="credentials_file=${GOOGLE_APPLICATION_CREDENTIALS}"
                                        """
                                    }
                                }
                            } else if (provider == 'azure') {
                                withCredentials([
                                    string(credentialsId: env.AZURE_CLIENT_ID_CRED_ID, variable: 'ARM_CLIENT_ID'),
                                    string(credentialsId: env.AZURE_CLIENT_SECRET_CRED_ID, variable: 'ARM_CLIENT_SECRET'),
                                    string(credentialsId: env.AZURE_SUBSCRIPTION_ID_CRED_ID, variable: 'ARM_SUBSCRIPTION_ID'),
                                    string(credentialsId: env.AZURE_TENANT_ID_CRED_ID, variable: 'ARM_TENANT_ID'),
                                    string(credentialsId: env.TWILIO_AUTH_TOKEN_CRED_ID, variable: 'twilio_auth_token')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Applying Terraform configuration for Azure..."
                                        //sh "terraform import azurerm_kubernetes_cluster.aks_cluster \"/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/hello-world-app-rg/providers/Microsoft.ContainerService/managedClusters/hello-world-aks-cluster\""
                                        sh """
                                        terraform apply -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image=helloworldappregistry.azurecr.io/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                            -var="tenant_id=${ARM_TENANT_ID}"
                                        """
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying Azure resources..."
                                        sh """
                                        terraform destroy -auto-approve \
                                            -var="twilio_auth_token=${twilio_auth_token}" \
                                            -var="docker_image=helloworldappregistry.azurecr.io/hello-world-repo:${DOCKER_IMAGE_TAG}" \
                                            -var="tenant_id=${ARM_TENANT_ID}"
                                        """
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
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID],
                        string(credentialsId: env.AWS_HOSTED_ZONE_ID_CRED_ID, variable: 'AWS_HOSTED_ZONE_ID'),
                        string(credentialsId: env.AWS_ACCOUNT_ID_CRED_ID, variable: 'AWS_ACCOUNT_ID')
                    ]) {
                        // Collect the endpoints from each provider

                        // AWS Endpoint
                        def awsEndpoint = ''
                        dir('terraform-AWS') {
                            // Initialize Terraform to access the remote backend
                            sh 'terraform init -input=false -backend=true'
                            
                            // Fetch the LoadBalancer DNS (assuming it's a DNS name)
                            awsEndpoint = sh(
                                script: "terraform output -raw alb_dns_name",
                                returnStdout: true
                            ).trim()
                        }

                        // GCP Endpoint
                        def gcpEndpoint = ''
                        dir('terraform-GCP') {
                            // Initialize Terraform to access the remote backend
                            sh 'terraform init -input=false -backend=true'
                            
                            // Fetch the LoadBalancer IP
                            gcpEndpoint = sh(
                                script: "terraform output -raw application_external_ip",
                                returnStdout: true
                            ).trim()
                        }

                        // Azure Endpoint
                        def azureEndpoint = ''
                        dir('terraform-AZURE') {
                            // Initialize Terraform to access the remote backend
                            sh 'terraform init -input=false -backend=true'
                            
                            // Fetch the LoadBalancer IP
                            azureEndpoint = sh(
                                script: "terraform output -raw load_balancer_ip",
                                returnStdout: true
                            ).trim()
                        }

                        // Update Route 53 DNS records to point to the endpoints
                        sh """
                        aws route53 change-resource-record-sets --hosted-zone-id ${AWS_HOSTED_ZONE_ID} --change-batch '{
                            "Comment": "Update record to add multi-cloud endpoints",
                            "Changes": [
                                {
                                    "Action": "UPSERT",
                                    "ResourceRecordSet": {
                                        "Name": "${AWS_DOMAIN_NAME}.",
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
                allOf {
                    expression { params.ACTION == 'deploy' }
                    expression { params.CLOUD_PROVIDER == 'all' }
                }
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
