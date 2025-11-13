output "db_endpoint" {
  value = aws_db_instance.db.address
}

output "ecs_service_name" {
  value = aws_ecs_service.hr_service.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.hr_cluster.name
}
