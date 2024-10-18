variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  default     = "hello-world-app"
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive = true
}

variable "twilio_phone_number" {
  description = "Twilio phone number"
  type        = string
  default     = 18449410220
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  default     = 1
}

variable "domain_name" {
  description = "The domain name for the application"
  default     = "text18449410220anything-zwinger.org"
}

variable "log_retention_in_days" {
  description = "Number of days to retain logs in CloudWatch"
  default     = 5
}

# variable "contact_first_name" {
#   description = "The contact's first name"
#   type        = string
#   default     = "Thomas"
#   sensitive   = true
# }

# variable "contact_last_name" {
#   description = "The contact's last name"
#   type        = string
#   default     = "Zwinger"
#   sensitive   = true
# }

# variable "contact_address" {
#   description = "The contact's address"
#   type        = string
#   default     = "405 Main St, Apt 303"
#   sensitive   = true
# }

# variable "contact_city" {
#   description = "The contact's city"
#   type        = string
#   default     = "Red Wing"
#   sensitive   = true
# }

# variable "contact_state" {
#   description = "The contact's state"
#   type        = string
#   default     = "MN"
#   sensitive   = true
# }

# variable "contact_country" {
#   description = "The contact's country code"
#   type        = string
#   default     = "US"
#   sensitive   = true
# }

# variable "contact_zip" {
#   description = "The contact's ZIP code"
#   type        = string
#   default     = "55066"
#   sensitive   = true
# }

# variable "contact_phone" {
#   description = "The contact's phone number"
#   type        = string
#   default     = "+19526864444"
#   sensitive   = true
# }

# variable "contact_email" {
#   description = "The contact's email"
#   type        = string
#   default     = "zwingthomas@gmail.com"
#   sensitive   = true
# }

