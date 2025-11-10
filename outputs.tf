output "web1_public_ip" {
  value = aws_instance.web1.public_ip
}

output "web2_public_ip" {
  value = aws_instance.web2.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.db.address
}

output "load_balancer_dns" {
  value = aws_lb.web_lb.dns_name
}