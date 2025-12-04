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

# Build en push Docker image naar ECR
resource "null_resource" "push_to_ecr" {
  # Trigger rebuild bij wijzigingen in website directory
  triggers = {
    dockerfile_hash = filesha256("${path.module}/website/Dockerfile")
    app_hash       = filesha256("${path.module}/website/index.php")
  }

  provisioner "local-exec" {
    command = <<EOF
      # Login naar ECR
      aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.website.repository_url}
      
      # Build image
      docker build -t ${aws_ecr_repository.website.repository_url}:latest ${path.module}/website
      
      # Push image
      docker push ${aws_ecr_repository.website.repository_url}:latest
    EOF
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
      image     = "${aws_ecr_repository.website.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      # Environment variables voor PHP app
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.db.address
        },
        {
          name  = "DB_NAME"
          value = "innovatech"
        },
        {
          name  = "DB_USER"
          value = "admin"
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]
      # Logging configuratie
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/web-task"
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
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