
module "network" {
  source               = "../modules/network"
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecr" {
  source  = "../modules/ecr"
  project = var.project
  repos   = ["patient-service", "appointment-service"]
}

module "ecs" {
  source             = "../modules/ecs"
  project            = var.project
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  region             = var.region

  patient_image     = "${module.ecr.repository_urls["patient-service"]}:${var.patient_image_tag}"
  appointment_image = "${module.ecr.repository_urls["appointment-service"]}:${var.appointment_image_tag}"

  desired_count_patient     = var.desired_count_patient
  desired_count_appoin
tment = var.desired_count_appointment
}

module "alb" {
  source             = "../modules/alb"
  project            = var.project
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  ecs_sg_id          = module.ecs.service_sg_id
  patient_tg_arn     = module.ecs.patient_tg_arn
  appointment_tg_arn = module.ecs.appointment_tg_arn
}

module "observability" {
  source  = "../modules/observability"
  project = var.project
  alb_arn = module.alb.alb_arn
  ecs_cluster_name        = module.ecs.cluster_name
  patient_service_name    = module.ecs.patient_service_name
  appointment_service_name= module.ecs.appointment_service_name
}
