output "app_url" {
  description = "The URL of the App Runner application."
  value       = aws_apprunner_service.acrn_app.service_url
}
