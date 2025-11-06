output "web_public_ip" {
  value = aws_instance.web1.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.db.address
}
