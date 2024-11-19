pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'destroy', 'rebalance'], description: 'Select action to perform')
        choice(name: 'CLOUD_PROVIDER', choices: ['gcp', 'aws', 'azure', 'all'], description: 'Select cloud provider(s) (ignored if ACTION is rebalance)')
    }

    environment {

        // Common environment variables
        DOCKER_IMAGE_NAME            = 'hello-world-app'
        DOCKER_IMAGE_TAG             = "${env.BUILD_NUMBER}"
        APPLICATION_URL              = 'zwingers.us'

        // Credentials IDs (these are not the secrets themselves)
        TWILIO_AUTH_TOKEN_CRED_ID    = 'twilio-auth-token'                // Jenkins credentials ID for Twilio Auth Token

        // AWS-specific environment variables
        AWS_REGION                   = 'us-east-1'
        AWS_ECR_REPO_NAME            = 'hello-world-app-repo'
        AWS_CREDENTIALS_ID           = 'aws-credentials'                  // Jenkins credentials ID for AWS
        AWS_ACCOUNT_ID_CRED_ID       = 'aws-account-id'                   // Jenkins credentials ID for AWS Account ID
        AWS_HOSTED_ZONE_ID_CRED_ID   = 'aws-hosted-zone-id'               // Jenkins credentials ID for AWS Hosted Zone ID
        AWS_DOMAIN_NAME              = "${APPLICATION_URL}"

        // GCP-specific environment variables
        GCP_PROJECT_ID               = 'gcp-project'                      // Jenkins credentials ID for GCP Project
        GCP_CREDENTIALS_ID           = 'gcp-credentials-file'             // Jenkins credentials ID for GCP Service Account Key

        // Azure-specific environment variables
        AZURE_ACR_CREDENTIALS_ID     = 'azure-acr-credentials'            // Jenkins credentials ID for Azure ACR

        // Azure credentials IDs for Terraform
        AZURE_CLIENT_ID_CRED_ID         = 'azure-client-id'               // Jenkins credentials ID for Azure Client ID
        AZURE_CLIENT_SECRET_CRED_ID     = 'azure-client-secret'           // Jenkins credentials ID for Azure Client Secret
        AZURE_SUBSCRIPTION_ID_CRED_ID   = 'azure-subscription-id'         // Jenkins credentials ID for Azure Subscription ID
        AZURE_TENANT_ID_CRED_ID         = 'azure-tenant-id'               // Jenkins credentials ID for Azure Tenant ID
    }

    stages {

        stage('Get Jenkins Public IP') {
            steps {
                script {
                    env.JENKINS_IP = sh(script: "curl -s http://checkip.amazonaws.com/", returnStdout: true).trim()
                    echo "Retrieved JENKINS_IP: ${env.JENKINS_IP}"
                }
            }
        }

        stage('Print JENKINS_IP') {
            steps {
                echo "JENKINS_IP is: ${env.JENKINS_IP}"
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/zwingthomas/Text2Site.git'
            }
        }

        // Only build and push Docker image if the action is 'deploy'
        stage('Build Docker Image') {
            when {
                allOf {
                    expression { params.ACTION == 'deploy' }
                    not { expression { params.CLOUD_PROVIDER == 'rebalance' } }
                }
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
                                // Use Jenkins credentials securely
                                withCredentials([
                                    usernamePassword(credentialsId: 'azure-acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')
                                ]) {
                                    try {
                                        echo "Logging in to Azure Container Registry"

                                        // Login to ACR
                                        sh """
                                        docker login helloworldappregistry.azurecr.io \
                                            --username ${ACR_USERNAME} \
                                            --password ${ACR_PASSWORD}
                                        """
                                    }
                                    catch (Exception e) {
                                        echo "Docker Azure Container Registry authentication failed with exception: ${e}"
                                        currentBuild.result = 'FAILURE'
                                        throw e
                                    }
                                    try {
                                        echo "Building Docker Image for ARM64: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                                        sh """
                                        # Enable QEMU emulation
                                        docker run --privileged --rm tonistiigi/binfmt --install all

                                        # Remove existing builder if it exists
                                        docker buildx rm mybuilder || true

                                        # Create and use a new builder
                                        docker buildx create --use --name mybuilder

                                        # Use the builder
                                        docker buildx use mybuilder
                                        """
                                    }
                                    catch (Exception e) {
                                        echo "Docker build presteps failed with exception: ${e}"
                                        currentBuild.result = 'FAILURE'
                                        throw e
                                    }
                                    try {
                                        sh """
                                        # Build and push the ARM64 image with verbose output
                                        docker buildx build --platform linux/arm64 \
                                            --progress=plain --no-cache \
                                            -t helloworldappregistry.azurecr.io/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                                            --push ./src

                                        # Clean up the builder
                                        docker buildx rm mybuilder
                                        """
                                        echo "Docker Image built and pushed successfully."
                                    } catch (Exception e) {
                                        echo "Docker build/push failed with exception: ${e}"
                                        currentBuild.result = 'FAILURE'
                                        throw e
                                    }
                                }
                            }
                        } else {
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
                allOf {
                    expression { params.ACTION == 'deploy' }
                    not { expression { params.CLOUD_PROVIDER == 'rebalance' } }
                }
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
                            withCredentials([
                                file(credentialsId: env.GCP_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                                string(credentialsId: 'gcp-project', variable: 'GCP_PROJECT_ID')
                            ]) {
                                sh """
                                gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                                gcloud config set project ${GCP_PROJECT_ID}
                                gcloud auth configure-docker us-central1-docker.pkg.dev
                                docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                docker push us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Init and Apply/Destroy') {
            when {
                not { expression { params.ACTION == 'rebalance' } }
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
                        dir("terraform-${provider.toUpperCase()}") {
                            if (provider == 'aws') {
                                withCredentials([
                                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID],
                                    string(credentialsId: env.AWS_ACCOUNT_ID_CRED_ID, variable: 'AWS_ACCOUNT_ID')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Planning Terraform configuration for AWS..."
                                        withCredentials([string(credentialsId: env.TWILIO_AUTH_TOKEN_CRED_ID, variable: 'twilio_auth_token')]) {
                                            try {
                                                def planStatus = sh(
                                                    script: """
                                                    terraform plan -detailed-exitcode \
                                                        -var="docker_image_tag=${BUILD_NUMBER}" \
                                                        -var twilio_auth_token=\$twilio_auth_token \
                                                        -var aws_region=${env.AWS_REGION} \
                                                        -var create_ecr_repo=false \
                                                        -out=tfplan
                                                    """,
                                                    returnStatus: true
                                                )

                                                if (planStatus == 0) {
                                                    echo "No changes detected in AWS infrastructure. Skipping terraform apply."
                                                } else if (planStatus == 2) {
                                                    echo "Changes detected in AWS infrastructure. Applying changes..."
                                                    def applyResult = sh(
                                                        script: "terraform apply -auto-approve tfplan",
                                                        returnStatus: true
                                                    )
                                                    if (applyResult != 0) {
                                                        error "Terraform apply failed with exit code ${applyResult}"
                                                    } else {
                                                        echo "Terraform apply succeeded."
                                                    }
                                                } else {
                                                    error "Terraform plan failed with exit code ${planStatus}"
                                                }
                                            } catch (Exception e) {
                                                echo "Terraform plan/apply failed: ${e}"
                                                currentBuild.result = 'FAILURE'
                                                throw e
                                            } finally {
                                                // Clean up plan file
                                                sh 'rm -f tfplan'
                                            }
                                        }
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying AWS resources..."
                                        try {
                                            def destroyResult = sh(
                                                script: """
                                                terraform destroy -auto-approve \
                                                    -var="docker_image_tag=${BUILD_NUMBER}" \
                                                    -var twilio_auth_token=\$twilio_auth_token \
                                                    -var aws_region=${env.AWS_REGION} \
                                                    -var create_ecr_repo=false
                                                """,
                                                returnStatus: true
                                            )
                                            if (destroyResult != 0) {
                                                error "Terraform destroy failed with exit code ${destroyResult}"
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
                                // Similar logic for GCP
                                withCredentials([
                                    file(credentialsId: env.GCP_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                                    string(credentialsId: env.TWILIO_AUTH_TOKEN_CRED_ID, variable: 'twilio_auth_token'),
                                    string(credentialsId: 'gcp-project', variable: 'GCP_PROJECT_ID')
                                ]) {
                                    sh "terraform init"
                                    if (params.ACTION == 'deploy') {
                                        echo "Planning Terraform configuration for GCP..."
                                        try {
                                            def planStatus = sh(
                                                script: """
                                                terraform plan -detailed-exitcode \
                                                    -var="twilio_auth_token=${twilio_auth_token}" \
                                                    -var="docker_image_tag=us-central1-docker.pkg.dev/${env.GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                                    -var="project_id=${env.GCP_PROJECT_ID}" \
                                                    -var="credentials_file=${GOOGLE_APPLICATION_CREDENTIALS}" \
                                                    -out=tfplan
                                                """,
                                                returnStatus: true
                                            )

                                            if (planStatus == 0) {
                                                echo "No changes detected in GCP infrastructure. Skipping terraform apply."
                                            } else if (planStatus == 2) {
                                                echo "Changes detected in GCP infrastructure. Applying changes..."
                                                def applyResult = sh(
                                                    script: "terraform apply -auto-approve tfplan",
                                                    returnStatus: true
                                                )
                                                if (applyResult != 0) {
                                                    error "Terraform apply failed with exit code ${applyResult}"
                                                } else {
                                                    echo "Terraform apply succeeded."
                                                }
                                            } else {
                                                error "Terraform plan failed with exit code ${planStatus}"
                                            }
                                        } catch (Exception e) {
                                            echo "Terraform plan/apply failed: ${e}"
                                            currentBuild.result = 'FAILURE'
                                            throw e
                                        } finally {
                                            // Clean up plan file
                                            sh 'rm -f tfplan'
                                        }
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying GCP resources..."
                                        try {
                                            def destroyResult = sh(
                                                script: """
                                                terraform destroy -auto-approve \
                                                    -var="twilio_auth_token=${twilio_auth_token}" \
                                                    -var="docker_image_tag=us-central1-docker.pkg.dev/${env.GCP_PROJECT_ID}/hello-world-app/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                                    -var="project_id=${env.GCP_PROJECT_ID}" \
                                                    -var="credentials_file=${GOOGLE_APPLICATION_CREDENTIALS}"
                                                """,
                                                returnStatus: true
                                            )
                                            if (destroyResult != 0) {
                                                error "Terraform destroy failed with exit code ${destroyResult}"
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
                                        echo "Planning Terraform configuration for Azure..."
                                        try {
                                            def planStatus = sh(
                                                script: """
                                                terraform plan -detailed-exitcode \
                                                    -var="twilio_auth_token=${twilio_auth_token}" \
                                                    -var="docker_image=helloworldappregistry.azurecr.io/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                                                    -var="tenant_id=${ARM_TENANT_ID}" \
                                                    -var="jenkins_ip=${env.JENKINS_IP}" \
                                                    -out=tfplan
                                                """,
                                                returnStatus: true
                                            )

                                            if (planStatus == 0) {
                                                echo "No changes detected in Azure infrastructure. Skipping terraform apply."
                                            } else if (planStatus == 2) {
                                                echo "Changes detected in Azure infrastructure. Applying changes..."
                                                def applyResult = sh(
                                                    script: "terraform apply -auto-approve tfplan",
                                                    returnStatus: true
                                                )
                                                if (applyResult != 0) {
                                                    error "Terraform apply failed with exit code ${applyResult}"
                                                } else {
                                                    echo "Terraform apply succeeded."
                                                }
                                            } else {
                                                error "Terraform plan failed with exit code ${planStatus}"
                                            }
                                        } catch (Exception e) {
                                            echo "Terraform plan/apply failed: ${e}"
                                            currentBuild.result = 'FAILURE'
                                            throw e
                                        } finally {
                                            // Clean up plan file
                                            sh 'rm -f tfplan'
                                        }
                                    } else if (params.ACTION == 'destroy') {
                                        echo "Destroying Azure resources..."
                                        try {
                                            def destroyResult = sh(
                                                script: """
                                                terraform destroy -auto-approve \
                                                    -var="twilio_auth_token=${twilio_auth_token}" \
                                                    -var="docker_image=helloworldappregistry.azurecr.io/hello-world-repo:${DOCKER_IMAGE_TAG}" \
                                                    -var="tenant_id=${ARM_TENANT_ID}" \
                                                    -var="jenkins_ip=${env.JENKINS_IP}"
                                                """,
                                                returnStatus: true
                                            )
                                            if (destroyResult != 0) {
                                                error "Terraform destroy failed with exit code ${destroyResult}"
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
                            }
                        }
                    }
                }
            }
        }

        // Only set up the global load balancer if deploying to all providers or rebalancing
        stage('Set Up Global Load Balancer') {
            when {
                anyOf {
                    allOf {
                        expression { params.ACTION == 'deploy' }
                        expression { params.CLOUD_PROVIDER == 'all' }
                    }
                    expression { params.ACTION == 'rebalance' }
                }
            }
            steps {
                script {
                    echo "Setting up global load balancer and DNS..."
                    def awsEndpoint = ''
                    def gcpEndpoint = ''
                    def azureEndpoint = ''

                    // Fetch endpoints from each provider
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID],
                        string(credentialsId: env.AWS_HOSTED_ZONE_ID_CRED_ID, variable: 'AWS_HOSTED_ZONE_ID')
                    ]) {
                        // AWS Endpoint
                        dir('terraform-AWS') {
                            sh 'terraform init -input=false -backend=true'
                            awsEndpoint = sh(script: "terraform output -raw alb_dns_name", returnStdout: true).trim()
                            AWS_ENDPOINT_HOSTED_ZONE_ID = sh(script: "terraform output -raw alb_hosted_zone_id", returnStdout: true).trim()
                        }

                        // GCP Endpoint
                        withCredentials([
                            file(credentialsId: env.GCP_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                            string(credentialsId: 'gcp-project', variable: 'GCP_PROJECT_ID')
                        ]) {
                            dir('terraform-GCP') {
                                sh 'terraform init -input=false -backend=true'
                                gcpEndpoint = sh(script: "terraform output -raw application_external_ip", returnStdout: true).trim()
                            }
                        }

                        // Azure Endpoint
                        withCredentials([
                            string(credentialsId: env.AZURE_CLIENT_ID_CRED_ID, variable: 'ARM_CLIENT_ID'),
                            string(credentialsId: env.AZURE_CLIENT_SECRET_CRED_ID, variable: 'ARM_CLIENT_SECRET'),
                            string(credentialsId: env.AZURE_SUBSCRIPTION_ID_CRED_ID, variable: 'ARM_SUBSCRIPTION_ID'),
                            string(credentialsId: env.AZURE_TENANT_ID_CRED_ID, variable: 'ARM_TENANT_ID')
                        ]) {
                            dir('terraform-AZURE') {
                                sh 'terraform init -input=false -backend=true'
                                azureEndpoint = sh(script: "terraform output -raw load_balancer_ip", returnStdout: true).trim()
                            }
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
                                        "AliasTarget": {
                                            "HostedZoneId": "${AWS_ENDPOINT_HOSTED_ZONE_ID}",
                                            "DNSName": "${awsEndpoint}",
                                            "EvaluateTargetHealth": true
                                        },
                                        "Weight": 33,
                                        "SetIdentifier": "aws-endpoint"
                                    }
                                },
                                {
                                    "Action": "UPSERT",
                                    "ResourceRecordSet": {
                                        "Name": "${AWS_DOMAIN_NAME}.",
                                        "Type": "A",
                                        "TTL": 60,
                                        "ResourceRecords": [
                                            {"Value": "${gcpEndpoint}"}
                                        ],
                                        "Weight": 33,
                                        "SetIdentifier": "gcp-endpoint"
                                    }
                                },
                                {
                                    "Action": "UPSERT",
                                    "ResourceRecordSet": {
                                        "Name": "${AWS_DOMAIN_NAME}.",
                                        "Type": "A",
                                        "TTL": 60,
                                        "ResourceRecords": [
                                            {"Value": "${azureEndpoint}"}
                                        ],
                                        "Weight": 34,
                                        "SetIdentifier": "azure-endpoint"
                                    }
                                }
                            ]
                        }'
                        """
                        echo "Load balancer set up successfully."
                    }
                }
            }
        }

        // Only perform verification if deploying to all providers
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
