resource "aws_ecr_repository" "repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  # force_delete = true
  # do not delete as then the pipeline will not build again

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}
