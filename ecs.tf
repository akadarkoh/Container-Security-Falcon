resource "aws_ecs_cluster" "falcon_cluster" {
  name = "falcon-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "falcon-ecs-cluster"
  }
}

resource "aws_cloudwatch_log_group" "falcon_ecs_log_group" {
  name              = "/aws/ecs/falcon-service"
  retention_in_days = 7

  tags = {
    Name = "falcon-ecs-logs"
  }
}

resource "aws_iam_role" "falcon_ecs_task_execution_role" {
  name = "falcon-ecs-task-execution-role"
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

  tags = {
    Name = "falcon-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "falcon_ecs_task_execution_policy" {
  role       = aws_iam_role.falcon_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "falcon_alb" {
  name               = "falcon-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.falcon_alb_sg.id]
  subnets            = [aws_subnet.falcon_public_subnet_a.id, aws_subnet.falcon_public_subnet_b.id]

  tags = {
    Name = "falcon-alb"
  }
}

resource "aws_lb_target_group" "falcon_tg" {
  name        = "falcon-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.falcon_vpc.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
  }

  tags = {
    Name = "falcon-tg"
  }
}

resource "aws_lb_listener" "falcon_http_listener" {
  load_balancer_arn = aws_lb.falcon_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.falcon_tg.arn
  }
}

locals {
  falcon_container_name = "falcon-app"
  falcon_container_port = 80
}

resource "aws_ecs_task_definition" "falcon_task" {
  family                   = "falcon-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.falcon_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = local.falcon_container_name
      image     = "${data.aws_ecr_repository.falcon_ecr_repository.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = local.falcon_container_port
          hostPort      = local.falcon_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.falcon_ecs_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "falcon"
        }
      }
    }
  ])

  tags = {
    Name = "falcon-task"
  }
}

resource "aws_ecs_service" "falcon_service" {
  name            = "falcon-service"
  cluster         = aws_ecs_cluster.falcon_cluster.id
  task_definition = aws_ecs_task_definition.falcon_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.falcon_service_sg.id]
    subnets          = [aws_subnet.falcon_public_subnet_a.id, aws_subnet.falcon_public_subnet_b.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.falcon_tg.arn
    container_name   = local.falcon_container_name
    container_port   = local.falcon_container_port
  }

  depends_on = [
    aws_lb_listener.falcon_http_listener
  ]

  tags = {
    Name = "falcon-service"
  }
}
