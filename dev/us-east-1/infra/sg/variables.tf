variable "alb_source_cidr" {
  type = string
}

variable "alb_port" {
  type = string
}


variable "rds_port" {
  type = string
}

variable "vpc_name_prefix" {
  type = string
}

variable "env" {
  type    = string
  default = ""
}
