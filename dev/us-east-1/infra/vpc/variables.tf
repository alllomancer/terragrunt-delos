variable "name" {
  description = "Name to be used on"
  type        = string
  default     = ""
}

variable "region" {
  description = "the region name"
  type        = string
  default     = ""
}

variable "env" {
  type    = string
  default = ""
}

variable "num_of_az" {
  type    = number
  default = 3
}

variable "cidr_block" {
  type = string
}

variable "vpc_name_prefix" {
  type = string
}
