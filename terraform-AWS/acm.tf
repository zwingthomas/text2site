# Create certificate
# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   tags = {
#     Name = "my-ssl-cert"
#   }
# }