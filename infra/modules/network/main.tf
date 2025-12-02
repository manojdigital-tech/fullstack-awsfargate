
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc_this.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc_this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.project}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc_this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.project}-private-${count.index}" }
}

data "aws_availability_zones" "available" {}

resource "aws_eip" "nat" { vpc = true }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip_nat.id
  subnet_id     = aws_subnet_public[0].id
  tags          = { Name = "${var.project}-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc_this.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway_igw.id }
  tags  = { Name = "${var.project}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet_public)
  subnet_id      = aws_subnet_public[count.index].id
  route_table_id = aws_route_table_public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc_this.id
  route { cidr_block = "0.0.0.0/0", nat_gateway_id = aws_nat_gateway_nat.id }
  tags  = { Name = "${var.project}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet_private)
  subnet_id      = aws_subnet_private[count.index].id
  route_table_id = aws_route_table_private.id
}

output "vpc_id"              { value = aws_vpc_this.id }
output "public_subnet_ids"   { value = aws_subnet_public[*].id }
output "private_subnet_ids"  { value = aws_subnet_private[*].id }
