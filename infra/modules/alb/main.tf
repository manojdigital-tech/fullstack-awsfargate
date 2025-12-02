
variable "project" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "ecs_sg_id" {}
variable "patient_tg_arn" {}
variable "appointment_tg_arn" {}

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = var.vpc_id
  ingress { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

# Allow ALB to call ECS service SG on 3000
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group_alb.id
  security_group_id        = var.ecs_sg_id
}

resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group_alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb_this.arn
  port              = 80
  protocol          = "HTTP"
  default_action { type = "fixed-response", fixed_response { content_type = "text/plain", status_code = "404", message_body = "Not Found" } }
}

resource "aws_lb_listener_rule" "patient_path" {
  listener_arn = aws_lb_listener_http.arn
  priority     = 10
  action { type = "forward", target_group_arn = var.patient_tg_arn }
  condition { path_pattern { values = ["/patients*", "/patients/*"] } }
}

resource "aws_lb_listener_rule" "appointment_path" {
  listener_arn = aws_lb_listener_http.arn
  priority     = 20
  action { type = "forward", target_group_arn = var.appointment_tg_arn }
  condition { path_pattern { values = ["/appointments*", "/appointments/*"] } }
}

output "alb_dns_name" { value = aws_lb_this.dns_name }
