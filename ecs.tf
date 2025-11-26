resource "aws_ecs_cluster" "webcluster" {
  name = "webcluster"
}

resource "aws_iam_role" "ecs_exec_role" {
  name = "ecs_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012_10_17"
    Statement = [
      {
        Action = "sts_AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs_tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service_role_AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "webtask" {
  family                   = "webtask"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([
    {
      name  = "web"
      image = "nginx"
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

resource "aws_ecs_service" "webservice" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.webcluster.id
  task_definition = aws_ecs_task_definition.webtask.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.web_subnet.id]
    assign_public_ip = true
    security_groups = [aws_security_group.web_sg.id]
  }
}
