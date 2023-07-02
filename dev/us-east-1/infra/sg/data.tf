

data "aws_vpc" "current" {
  tags = {
    Name = "${var.vpc_name_prefix}-${var.env}"
  }
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.current.id
}
