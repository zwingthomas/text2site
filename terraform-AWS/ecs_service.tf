# Check if it exists
data "aws_iam_role" "ecs_service_linked_role" {
  name = "AWSServiceRoleForECS"
}

# Force role generation
resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"

  # Only create if it does not exist
  count = try(length(data.aws_iam_role.ecs_service_linked_role.arn), 0) == 0 ? 1 : 0

  # Ensure this role is only deleted after the ECS cluster is destroyed
  depends_on = [
    aws_ecs_cluster.cluster,           # Wait for the ECS cluster to be destroyed
    aws_ecs_service.service,           # Wait for the ECS service to be destroyed
    aws_ecs_task_definition.task,      # Ensure tasks are destroyed
    aws_lb_target_group.app_tg,        # Ensure target groups are destroyed
    aws_security_group.ecs_sg          # Ensure security groups are destroyed
  ]
}

# Create elastic container service
resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets            = [for subnet in aws_subnet.public : subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app"
    container_port   = 80
  }

  depends_on = [
    aws_ecs_task_definition.task,
    aws_lb_target_group.app_tg,      
    aws_lb_listener.http
  ]

  tags = {
    Name = "${var.project_name}-ecs-service"
  }
}
