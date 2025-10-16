data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_service.acrn_app.service_url]
}

resource "aws_apprunner_custom_domain_association" "acrn_domain" {
  domain_name = var.domain_name
  service_arn = aws_apprunner_service.acrn_app.arn
}
