# resource "aws_route53_domain" "my_domain" {
#   domain_name = var.domain_name
#   tags = {
#     Name = var.domain_name
#   }

#   admin_contact {
#     first_name   = var.contact_first_name
#     last_name    = var.contact_last_name
#     contact_type = "PERSON"
#     address_line_1 = var.contact_address
#     city         = var.contact_city
#     state        = var.contact_state
#     country_code = var.contact_country
#     zip_code     = var.contact_zip
#     phone_number = var.contact_phone
#     email        = var.contact_email
#   }

#   registrant_contact {
#     first_name   = var.contact_first_name
#     last_name    = var.contact_last_name
#     contact_type = "PERSON"
#     address_line_1 = var.contact_address
#     city         = var.contact_city
#     state        = var.contact_state
#     country_code = var.contact_country
#     zip_code     = var.contact_zip
#     phone_number = var.contact_phone
#     email        = var.contact_email
#   }

#   tech_contact {
#     first_name   = var.contact_first_name
#     last_name    = var.contact_last_name
#     contact_type = "PERSON"
#     address_line_1 = var.contact_address
#     city         = var.contact_city
#     state        = var.contact_state
#     country_code = var.contact_country
#     zip_code     = var.contact_zip
#     phone_number = var.contact_phone
#     email        = var.contact_email
#   }
# }


# resource "aws_route53_zone" "main" {
#   name = var.domain_name
# }

# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       type   = dvo.resource_record_type
#       value  = dvo.resource_record_value
#     }
#   }

#   zone_id = aws_route53_zone.main.zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.value]
#   ttl     = 300
# }

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# resource "aws_route53_record" "app_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = aws_lb.alb.dns_name
#     zone_id                = aws_lb.alb.zone_id
#     evaluate_target_health = false
#   }
# }