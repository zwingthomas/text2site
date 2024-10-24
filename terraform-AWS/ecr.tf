# Data source to reference an existing repository
data "aws_ecr_repository" "existing_repo" {
  count = var.create_ecr_repo ? 0 : 1
  name  = "hello-world-app-repo"
}

# Create new repo if one does not exist
resource "aws_ecr_repository" "repo" {

  # Only build if the data block was unable to fetch an existing repo
  count = length(data.aws_ecr_repository.existing_repo.id) == 0 ? 1 : 0

  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  # force_delete = true
  # do not delete as then the pipeline will not build again

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}
