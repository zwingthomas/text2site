# Sets up a load balancer for us to use which spans two zones
# Zones specified in vpc.tf
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Create a listener for the load balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}



# Points the load balancer to a set of servers
# Group is selected through the target resources themselves
# See ecs_service.tf
resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_name}-tg"
  port        = 5000 # the port we will recieve traffic
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check { # check health of targets
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}
