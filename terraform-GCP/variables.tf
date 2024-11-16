variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "List of zones within the region"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "hello-world-app-cluster-gcp"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for the cluster nodes"
  type        = string
  default     = "e2-medium"
}

variable "docker_image_tag" {
  description = "Docker image to deploy"
  type        = string
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
}

variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 80
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc-network"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pods_cidr" {
  description = "Secondary CIDR for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR for services"
  type        = string
  default     = "10.2.0.0/20"
}

variable "TRUSTED_IP_RANGE" {
  description = "Trusted IP range for accessing the Kubernetes API and SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_logging" {
  description = "Enable Cloud Logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "log_sink_destination" {
  description = "Destination for log sink"
  type        = string
  default     = ""  # Set your desired destination or leave empty if not using
}

variable "log_filter" {
  description = "Filter for logs to include in the sink"
  type        = string
  default     = "resource.type=\"k8s_container\""
}
