resource "aws_ecs_cluster" "main" {
  name = "khasm-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "khasm-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "khasm-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = local.ecs_execution_arn
  task_role_arn            = local.ecs_task_arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = aws_ecr_repository.backend.repository_url
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "NODE_ENV", value = var.environment },
        { name = "PORT", value = "3000" },
        { name = "DATABASE_URL", value = "postgresql://khasm:${random_password.db_password.result}@${aws_db_instance.postgres.endpoint}/khasmdb" },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "ANTHROPIC_API_KEY", value = var.anthropic_api_key },
        { name = "APIFY_API_KEY", value = var.apify_api_key },
        { name = "CLOUDINARY_CLOUD_NAME", value = var.cloudinary_cloud_name },
        { name = "CLOUDINARY_API_KEY", value = var.cloudinary_api_key },
        { name = "CLOUDINARY_API_SECRET", value = var.cloudinary_api_secret },
        { name = "DAILY_APIFY_BUDGET_USD", value = "10" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "khasm-${var.environment}-backend"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "backend" {
  name                   = "khasm-${var.environment}-backend"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.backend.arn
  desired_count          = var.ecs_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name        = "khasm-${var.environment}-backend"
    Environment = var.environment
  }
}

resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 10
  min_capacity       = var.ecs_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "khasm-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/khasm-${var.environment}-backend"
  retention_in_days = 30

  tags = {
    Name        = "khasm-${var.environment}-backend-logs"
    Environment = var.environment
  }
}
