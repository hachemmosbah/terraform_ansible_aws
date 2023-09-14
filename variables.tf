variable "aws_region" { # for AWS CLI
  description = "AWS region (e.g. `eu-west-3` => EU WEST EUROPE)"
  type        = string
  default     = "eu-west-3"
}
variable "aws_profile" { # for aws profile
  description = "AWS cli profile (e.g. `default`)"
  type        = string
  default     = "default"
}
variable "project" { # name of project
  description = "Project name used for tags"
  type        = string
  default     = "terraform_ansible_aws"
}
variable "availability_zones" {
  description = "Number of availability zones"
  type        = number
  default     = 1
}
variable "aws_vpc_cidr" { # for VPC
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}
variable "owner" {
  description = "Owner name used for tags"
  type        = string
  default     = "napo.io"
}