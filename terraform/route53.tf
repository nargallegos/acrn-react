data "aws_apprunner_hosted_zone_id" "current" {}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.app_name}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_apprunner_service.acrn_app.service_url
    zone_id                = data.aws_apprunner_hosted_zone_id.current.id
    evaluate_target_health = true
  }
}

resource "aws_apprunner_custom_domain_association" "acrn_domain" {
  domain_name = "${var.app_name}.${var.root_domain_name}"
  service_arn = aws_apprunner_service.acrn_app.arn
}
