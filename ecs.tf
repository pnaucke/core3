# CloudWatch Log Group voor container logs
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/webserver"
  retention_in_days = 7
}

# IAM role voor ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-web"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_amazon_ecs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

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
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

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
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}

# ECS service (Fargate) zonder Load Balancer; gebruikt jouw subnet en security group
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
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_amazon_ecs]
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.web_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.web_service.name
}
