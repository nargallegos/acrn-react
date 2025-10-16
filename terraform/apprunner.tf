resource "aws_apprunner_service" "acrn_app" {
  service_name = var.app_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_identifier      = "cele/acrn-react:602c73c"
      image_repository_type = "ECR"
      image_configuration {
        port = "3000"
      }
    }
    auto_deployments_enabled = true
  }

  tags = {
    Name      = var.app_name
    ManagedBy = "Terraform"
  }
}
