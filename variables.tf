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
variable "master_instance_type" {
  description = "EC2 instance type for K8s master instances"
  type        = string
  default     = "t2.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for K8s worker instances"
  type        = string
  default     = "t2.micro"
}

variable "aws_key_pair_name" {
  description = "AWS Key Pair name to use for EC2 Instances (if already existent)"
  type        = string
  default     = null
}
variable "ssh_public_key_path" {
  description = "SSH public key path (to create a new AWS Key Pair from existing local SSH public RSA key)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
variable "master_max_size" {
  description = "Maximum number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 1
}

variable "master_min_size" {
  description = "Minimum number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 1
}

variable "master_size" {
  description = "Desired number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 1
}

variable "worker_max_size" {
  description = "Maximum number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 2
}

variable "worker_min_size" {
  description = "Minimum number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 1
}

variable "worker_size" {
  description = "Desired number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 2
}