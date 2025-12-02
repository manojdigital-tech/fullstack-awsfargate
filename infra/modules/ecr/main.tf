
variable "project" { type = string }
variable "repos"   { type = list(string) }

locals {
  tags = { Project = var.project }
}

resource "aws_ecr_repository" "repos" {
  for_each                 = toset(var.repos)
  name                     = each.key
  image_tag_mutability     = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}

output "repository_urls" {
  value = { for name, repo in aws_ecr_repository_repos : name => repo.repository_url }
}
