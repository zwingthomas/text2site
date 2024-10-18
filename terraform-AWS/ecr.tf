resource "aws_ecr_repository" "repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}
