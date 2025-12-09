resource "aws_ecr_repository" "php_app" {
  name = "php-app"
}

resource "aws_ecr_lifecycle_policy" "php_app" {
  repository = aws_ecr_repository.php_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
      }
    ]
  })
}