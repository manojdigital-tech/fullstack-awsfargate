
variable "project" {}
variable "alb_arn" {}
variable "ecs_cluster_name" {}
variable "patient_service_name" {}
variable "appointment_service_name" {}

# Example alarms

# ALB 5xx
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  dimensions = {
    LoadBalancer = replace(var.alb_arn, "arn:aws:elasticloadbalancing:", "") # or use lb name via data source
  }
}

# ECS CPU > 80%
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.patient_service_name
  }
}
