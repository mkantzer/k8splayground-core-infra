# Only need to set up the actual zone.
# ExternalDNS will handle the actual records.

resource "aws_route53_zone" "cluster" {
  name = "${var.env}.clusters.kantzer.io"
}

# Output values needed to delegate subdomain

output "dns_zone_info" {
  description = "Information needed to delegate the subdomain to our hosted zone"
  value = {
    subdomain = aws_route53_zone.cluster.name
    name_servers = aws_route53_zone.cluster.name_servers
  }
}