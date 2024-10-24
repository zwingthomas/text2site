# Check if the repository already exists
data "aws_ecr_repository" "existing_repo" {
  name = "hello-world-app-repo"
}

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
