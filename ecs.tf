resource "aws_ecs_cluster" "hr_cluster" {
  name = "hr-cluster-${random_id.suffix.hex}"
}

resource "aws_ecs_task_definition" "hr_task" {
  family                   = "hr-task-${random_id.suffix.hex}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "hr-web"
    image     = "nginx:latest"
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "DB_HOST", value = aws_db_instance.db.address },
      { name = "DB_PORT", value = "5432" },
      { name = "DB_USER", value = "admin" },
      { name = "DB_PASS", value = var.db_password },
      { name = "DB_NAME", value = "myappdb" }
    ]
  }])
}

resource "aws_ecs_service" "hr_service" {
  name            = "hr-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.hr_cluster.id
  task_definition = aws_ecs_task_definition.hr_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.web_subnet.id]
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }
}
