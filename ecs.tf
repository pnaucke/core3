resource "aws_ecs_cluster" "hr_cluster" {
  name = "hr-cluster-${random_id.suffix.hex}"
}

resource "aws_ecs_task_definition" "hr_web_task" {
  family                   = "hr-web-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "hr-web"
      image     = "amazonlinux:2"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.db.address },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = "admin" },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = "hrdb" }
      ]
    }
  ])
}

resource "aws_ecs_service" "hr_web_service" {
  name            = "hr-web-service"
  cluster         = aws_ecs_cluster.hr_cluster.id
  task_definition = aws_ecs_task_definition.hr_web_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.web_subnet.id]
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }

  desired_count = 1
}
