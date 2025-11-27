# ECS Cluster
resource "aws_ecs_cluster" "webcluster" {
  name = "webcluster"
}

# IAM Role voor ECS tasks
resource "aws_iam_role" "ecs_exec_role" {
  name = "ecs_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# IAM policy attachment
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Check of Dockerfile bestaat
resource "null_resource" "check_dockerfile" {
  provisioner "local-exec" {
    command = "test -f ${path.module}/website/Dockerfile && echo 'Dockerfile found' || (echo 'Dockerfile missing' && exit 1)"
  }
}

# Docker image build en push naar ECR
resource "docker_image" "website" {
  name = "${aws_ecr_repository.website.repository_url}:latest"

  build {
    context    = "${path.module}/website"
    dockerfile = "${path.module}/website/Dockerfile"
  }

  keep_locally = false
  depends_on   = [null_resource.check_dockerfile]
}

# ECS Task Definition met PHP website image
resource "aws_ecs_task_definition" "web_task" {
  family                   = "web_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = docker_image.website.name
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "webservice" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.webcluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.web_subnet.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.web_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.web_listener,
    aws_nat_gateway.nat
  ]
}
