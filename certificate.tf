# SSL/TLS Certificate voor DuckDNS domein
resource "aws_acm_certificate" "ssl_cert" {
  # VERVANG MET JE DUCKDNS SUBDOMEIN:
  domain_name       = "innovatech-hr.duckdns.org"
  validation_method = "DNS"

  tags = {
    Name        = "duckdns-ssl-cert"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Omdat je geen Route53 hebt, moeten we de DNS records handmatig toevoegen
# Terraform kan deze output geven, jij moet ze handmatig in DuckDNS zetten
output "certificate_validation_records" {
  value = [
    for option in aws_acm_certificate.ssl_cert.domain_validation_options : {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  ]
  description = "DNS records to add to DuckDNS for certificate validation"
}

output "load_balancer_dns" {
  value       = aws_lb.web_lb.dns_name
  description = "Load Balancer DNS name"
}

output "duckdns_instructions" {
  value = <<-EOT
  === INSTRUCTIES VOOR DUCK DNS ===
  1. Ga naar https://www.duckdns.org/
  2. Klik op je domein: innovatech-hr.duckdns.org
  3. Voeg deze TXT record toe voor SSL validatie:
     - Name: ${aws_acm_certificate.ssl_cert.domain_validation_options[0].resource_record_name}
     - Value: ${aws_acm_certificate.ssl_cert.domain_validation_options[0].resource_record_value}
  4. Voeg deze A record toe voor de website:
     - Name: innovatech-hr (of @ voor root)
     - Type: CNAME
     - Value: ${aws_lb.web_lb.dns_name}
  5. Wacht 5-10 minuten voor DNS propagatie
  EOT
}