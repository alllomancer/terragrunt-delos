data "aws_vpc" "current" {
  tags = {
    Name = "${var.vpc_name_prefix}-${var.env}"
  }
}

data "aws_security_group" "alb_sg" {
  filter {
    name   = "tag:Name"
    values = ["alb_sg"]
  }
  vpc_id = data.aws_vpc.current.id
}

data "aws_security_group" "ecs_sg" {
  filter {
    name   = "tag:Name"
    values = ["ecs_sg"]
  }
  vpc_id = data.aws_vpc.current.id
}

data "aws_security_group" "rds_sg" {
  filter {
    name   = "tag:Name"
    values = ["rds_sg"]
  }
  vpc_id = data.aws_vpc.current.id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
  tags = {
    Tier = "public"
  }
}

data "aws_subnets" "database" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
  tags = {
    Tier = "database"
  }
}

data "aws_acm_certificate" "cert" {
  domain    = var.domain_name
  statuses  = ["ISSUED"]
  key_types = ["RSA_2048"]
}
