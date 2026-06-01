data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  ecs_execution_arn = "arn:aws:iam::${local.account_id}:role/khasm-${var.environment}-ecs-execution"
  ecs_task_arn      = "arn:aws:iam::${local.account_id}:role/khasm-${var.environment}-ecs-task"
}
