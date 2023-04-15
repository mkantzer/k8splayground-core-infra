# Only need to set up the actual zone.
# ExternalDNS will handle the actual records.

resource "aws_route53_zone" "cluster" {
  name          = "${var.env}.${var.dns_suffix}"
  force_destroy = true
}

# Delegate subdomain from primary hosted zone
data "aws_route53_zone" "primary" {
  name = var.dns_suffix
}

resource "aws_route53_record" "cluster_delegation" {
  name    = aws_route53_zone.cluster.name
  zone_id = data.aws_route53_zone.primary.id

  ttl     = 60
  type    = "NS"
  records = aws_route53_zone.cluster.name_servers
}

# Create and validate certificate

resource "aws_acm_certificate" "cluster_ingress" {
  domain_name               = "${var.env}.${var.dns_suffix}"
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.env}.${var.dns_suffix}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cluster_ingress_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cluster_ingress.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.cluster.zone_id
}

resource "aws_acm_certificate_validation" "cluster_ingress" {
  certificate_arn         = aws_acm_certificate.cluster_ingress.arn
  validation_record_fqdns = [for record in aws_route53_record.cluster_ingress_cert_validation : record.fqdn]
}
