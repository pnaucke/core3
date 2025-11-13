# ----------------------
# ECS Cluster
# ----------------------
resource "aws_ecs_cluster" "hr_cluster" {
  name = "hr-cluster-${random_id.suffix.hex}"
}

# ----------------------
# IAM Role voor ECS Task
# ----------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ----------------------
# ECS Task Definition
# ----------------------
resource "aws_ecs_task_definition" "hr_task" {
  family                   = "hr-web-task-${random_id.suffix.hex}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "hr-web"
    image     = "nginx:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "DB_HOST", value = aws_db_instance.db.address },
      { name = "DB_PORT", value = aws_db_instance.db.port },
      { name = "DB_USER", value = "admin" },
      { name = "DB_PASS", value = var.db_password },
      { name = "DB_NAME", value = "myappdb" }
    ]
  }])
}

# ----------------------
# ECS Fargate Service
# ----------------------
resource "aws_ecs_service" "hr_service" {
  name            = "hr-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.hr_cluster.id
  task_definition = aws_ecs_task_definition.hr_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.web_subnet.id]
    security_groups  = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}
