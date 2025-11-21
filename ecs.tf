# ECS cluster
resource "aws_ecs_cluster" "web_cluster" {
  name = "web-cluster"
}

# ECS task definition (Fargate) met nginx
resource "aws_ecs_task_definition" "web_task" {
  family                   = "webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "webserver"
      image     = "nginx:stable"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS service gekoppeld aan Load Balancer
resource "aws_ecs_service" "web_service" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = [aws_subnet.web_subnet.id]
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "webserver"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.web_listener_http]
}
