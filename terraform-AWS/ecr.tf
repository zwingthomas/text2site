resource "aws_ecr_repository" "repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}
