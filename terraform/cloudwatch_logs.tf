resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project_name}-log-group"
  }

  # Just to reassure
  lifecycle {
    prevent_destroy = false
  }
}
