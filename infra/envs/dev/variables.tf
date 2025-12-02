
variable "region" { type = string, default = "ap-southeast-2" }
variable "project" { type = string, default = "fargate-microservices" }

variable "vpc_cidr" { type = string, default = "10.0.0.0/16" }
variable "public_subnet_cidrs"  { type = list(string), default = ["10.0.0.0/24", "10.0.1.0/24"] }
variable "private_subnet_cidrs" { type = list(string), default = ["10.0.10.0/24", "10.0.11.0/24"] }

variable "patient_image_tag"     { type = string, default = "latest" }
variable "appointment_image_tag" { type = string, default = "latest" }

variable "desired_count_patient"     { type = number, default = 1 }

