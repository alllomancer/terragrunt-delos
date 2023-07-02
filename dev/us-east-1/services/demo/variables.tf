variable "name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_port" {
  type = number
}


variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "vpc_name_prefix" {
  type = string
}

variable "cluster_rds_instance_type" {
  type = string
}
