resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
  
  depends_on = [
    aws_vpc.main, 
    aws_subnet.public, 
    aws_internet_gateway.igw
  ]
}
