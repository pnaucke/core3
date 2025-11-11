output "web1_public_ip" {
  value = aws_instance.webserver1.public_ip
}

output "web2_public_ip" {
  value = aws_instance.webserver2.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.db.address
}

