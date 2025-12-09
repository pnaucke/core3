# SSL/TLS Certificate voor Cloudflare + DuckDNS
resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = "innovatech-hr.duckdns.org"
  validation_method = "DNS"

  tags = {
    Name = "cloudflare-ssl-cert"
  }
}

# Output met duidelijke instructies
output "cloudflare_setup_instructions" {
  value = <<-EOT
  ============ CLOUDFLARE SETUP ============
  
  STAP 1: Ga naar Cloudflare Dashboard → DNS → Records
  
  STAP 2: Voeg A record toe (voor nu):
     - Type: A
     - Name: @
     - Content: 82.170.150.87
     - Proxy: OFF (DNS only)
  
  STAP 3: Na 'terraform apply' krijg je TXT records.
          Voeg deze toe in Cloudflare voor SSL validatie.
  
  STAP 4: Wissel later A record voor CNAME naar Load Balancer.
  
  Website: https://innovatech-hr.duckdns.org
  =========================================
  EOT
}