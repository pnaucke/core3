# ECS Cluster
resource "aws_ecs_cluster" "webcluster" {
  name = "webcluster"
}

# IAM role voor ECS tasks
resource "aws_iam_role" "ecs_exec_role" {
  name = "ecs_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy attachment
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Bepaal unieke tag voor elke build
locals {
  image_tag = timestamp()
}

# Build en push Docker image naar ECR
resource "null_resource" "push_to_ecr" {
  triggers = {
    always_run = local.image_tag
  }

  provisioner "local-exec" {
    command = <<EOT
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 311471691447.dkr.ecr.eu-central-1.amazonaws.com/my-website
docker build -t 311471691447.dkr.ecr.eu-central-1.amazonaws.com/my-website:${local.image_tag} ${path.module}/website
docker push 311471691447.dkr.ecr.eu-central-1.amazonaws.com/my-website:${local.image_tag}
EOT
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "web_task" {
  depends_on = [null_resource.push_to_ecr]

  family                   = "web_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "311471691447.dkr.ecr.eu-central-1.amazonaws.com/my-website:${local.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "webservice" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.webcluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.web_subnet.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.web_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web"
    container_port   = 80
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_lb_listener.web_listener,
    aws_nat_gateway.nat
  ]
}
