resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags                 = merge(local.common_tags, map("Name", "${var.project_name}-main-${var.env}"))
}

# We need 2 subnets for the ALB as it requires 2 subnets in different AZs for HA
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.cidr_subnet_public, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = merge(local.common_tags, map("Name", "${var.project_name}-public${count.index}-${var.env}"))
}

resource "aws_internet_gateway" "main-gateway" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, map("Name", "${var.project_name}-main-${var.env}"))
}

resource "aws_route_table" "public-subnet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gateway.id
  }
  tags = merge(local.common_tags, map("Name", "${var.project_name}-public-${var.env}"))
}

resource "aws_route_table_association" "public-subnet" {
  count          = 2
  route_table_id = aws_route_table.public-subnet.id
  subnet_id      = element(list(aws_subnet.public.*.id[0], aws_subnet.public.*.id[1]), count.index)
}
