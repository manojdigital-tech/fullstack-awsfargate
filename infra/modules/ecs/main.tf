
variable "project" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "region" {}
variable "patient_image" {}
variable "appointment_image" {}
variable "desired_count_patient" { type = number }
variable "desired_count_appointment" { type = number }

resource "aws_security_group" "service" {
  name        = "${var.project}-svc-sg"
  description = "Allow ALB->ECS and egress to internet"
  vpc_id      = var.vpc_id
  egress { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}"
  retention_in_days = 14
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.project}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}
resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}

locals {
  container_common = {
    port   = 3000
    log    = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group_app.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
    env = [
      { name = "NODE_ENV", value = "production" }
      # add API URLs/DB connection via SSM/Secrets if needed
    ]
  }
}

# Task definitions
resource "aws_ecs_task_definition" "patient" {
  family                   = "${var.project}-patient"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role_task_execution.arn
  container_definitions    = jsonencode([
    {
      name  = "patient"
      image = var.patient_image
      portMappings = [{ containerPort = local.container_common.port, protocol = "tcp" }]
      logConfiguration = local.container_common.log
      environment     = local.container_common.env
      essential       = true
    }
  ])
}

resource "aws_ecs_task_definition" "appointment" {
  family                   = "${var.project}-appointment"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role_task_execution.arn
  container_definitions    = jsonencode([
    {
      name  = "appointment"
      image = var.appointment_image
      portMappings = [{ containerPort = local.container_common.port, protocol = "tcp" }]
      logConfiguration = local.container_common.log
      environment     = local.container_common.env
      essential       = true
    }
  ])
}

# Target groups (IP mode for Fargate)
resource "aws_lb_target_group" "patient" {
  name        = "${var.project}-patient-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { path = "/health" }
}

resource "aws_lb_target_group" "appointment" {
  name        = "${var.project}-appointment-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { path = "/health" }
}

# ECS services
resource "aws_ecs_service" "patient" {
  name            = "${var.project}-patient-svc"
  cluster         = aws_ecs_cluster_this.id
  task_definition = aws_ecs_task_definition_patient.arn
  desired_count   = var.desired_count_patient
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group_service.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group_patient.arn
    container_name   = "patient"
    container_port   = 3000
  }
  depends_on = [aws_lb_target_group_patient]
}

resource "aws_ecs_service" "appointment" {
  name            = "${var.project}-appointment-svc"
  cluster         = aws_ecs_cluster_this.id
  task_definition = aws_ecs_task_definition_appointment.arn
  desired_count   = var.desired_count_appointment
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group_service.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group_appointment.arn
    container_name   = "appointment"
    container_port   = 3000
  }
  depends_on = [aws_lb_target_group_appointment]
}

output "cluster_name"              { value = aws_ecs_cluster_this.name }
output "service_sg_id"             { value = aws_security_group_service.id }
output "patient_tg_arn"            { value = aws_lb_target_group_patient.arn }
output "appointment_tg_arn"        { value = aws_lb_target_group_appointment.arn }
output "patient_service_name"      { value = aws_ecs_service_patient.name }
output "appointment_service_name"  { value = aws_ecs_service_appointment.name }
