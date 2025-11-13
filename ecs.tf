# cluster
resource "aws_ecs_cluster" "web_cluster" {
  name = "web-cluster"
}

# webserver
resource "aws_ecs_task_definition" "web_task" {
  family                   = "web-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "web_service" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

network_configuration {
  subnets         = [aws_subnet.web_subnet.id]
  security_groups = [aws_security_group.web_sg.id]
  assign_public_ip = true
    }
}
