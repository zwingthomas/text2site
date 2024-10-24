output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value = (var.create_ecr_repo
    ? aws_ecr_repository.repo[0].repository_url
    : data.aws_ecr_repository.existing_repo[0].repository_url
  )
}

output "load_balancer_dns" {
  value = aws_lb.alb.dns_name
}
