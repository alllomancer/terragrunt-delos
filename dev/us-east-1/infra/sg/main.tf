
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "alb_sg"
  description = "alb security group"
  vpc_id      = data.aws_vpc.current.id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.alb_port
      to_port     = var.alb_port
      protocol    = "tcp"
      description = "alb"
      cidr_blocks = var.alb_source_cidr
    },
  ]
}

module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "ecs_sg"
  description = "ecs security group"
  vpc_id      = data.aws_vpc.current.id

  ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 0
      protocol                 = "tcp"
      description              = "ecs"
      source_security_group_id = module.alb_sg.security_group_id
    },
  ]
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "rds_sg"
  description = "rds security group"
  vpc_id      = data.aws_vpc.current.id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.rds_port
      to_port                  = var.rds_port
      protocol                 = "tcp"
      description              = "rds"
      source_security_group_id = module.ecs_sg.security_group_id
    },
  ]
}

