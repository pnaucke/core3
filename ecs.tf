# ECS Cluster en Service voor PHP webserver
resource "aws_ecs_cluster" "webcluster" {
  name = "webcluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "webserver" {
  family                   = "webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "webserver"
    image     = "${aws_ecr_repository.website.repository_url}:latest"
    cpu       = 512
    memory    = 1024
    essential = true
    
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    
    # HEALTH CHECK toegevoegd
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
    
    environment = [
      {
        name  = "APP_ENV"
        value = "production"
      },
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
        name  = "DB_PASS"
        value = var.db_password
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/webserver"
        "awslogs-region"        = "eu-central-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "webserver-task"
  }
}

resource "aws_ecs_service" "webservice" {
  name            = "webservice"
  cluster         = aws_ecs_cluster.webcluster.id
  task_definition = aws_ecs_task_definition.webserver.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  # Health check grace period - geef container tijd om op te starten
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = [aws_subnet.web_subnet.id]
    security_groups  = [aws_security_group.web_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "webserver"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.web_listener,
    null_resource.setup_database
  ]

  tags = {
    Name = "webservice"
  }
}

# Update de load balancer target group health check
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  # Verbeterde health check
  health_check {
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "web_tg"
  }
}

# IAM Rollen voor ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role_${random_id.suffix.hex}"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role_${random_id.suffix.hex}"

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

# CloudWatch Log Group voor ECS logs
resource "aws_cloudwatch_log_group" "ecs_webserver" {
  name              = "/ecs/webserver"
  retention_in_days = 7
}