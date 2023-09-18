
# Availability Zones
data "aws_availability_zones" "available" {
    state = "available"
}
## Get local workstation's external IPv4 address
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  # Optional request body
  request_body = "request body"
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}
# AWS VPC
resource "aws_vpc" "main" {
  cidr_block                       = var.aws_vpc_cidr
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
    Owner   = var.owner
  }
}

# Public Subnets
resource "aws_subnet" "private" {
  count             = var.availability_zones
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.aws_vpc_cidr, 8, count.index + 1)
  tags = {
    Name      = "${var.project}-private-${count.index}"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}

# aws gateawy
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
    Owner   = var.owner
  }
}

# aws Route table
## Private
resource "aws_route_table" "rt-private" {
  count  = var.availability_zones
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project}-rt-private"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}

# aws route table associations
## Private
resource "aws_route_table_association" "private-rtassoc" {
  count          = var.availability_zones
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.rt-private[count.index].id
}

#Security groups
resource "aws_security_group" "bastion-lb" {
  name_prefix = "bastion-lb-"
  description = "Bastion-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion-lb"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "etcd" {
  name_prefix = "etcd-"
  description = "etcd"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-etcd"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "master" {
  name_prefix = "terraform_ansible_aws"
  description = "terraform_ansible_aws"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-terraform_ansible_aws"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "taw-worker-"
  description = "taw Worker"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-taw-worker"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Security Group rules to add to above SecurityGroups
## Ingress
resource "aws_security_group_rule" "ssh" {
  for_each = {
    "Etcd"    = aws_security_group.etcd.id,
    "Masters" = aws_security_group.master.id,
    "Workers" = aws_security_group.worker.id,
  }
  security_group_id        = each.value
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  description              = "SSH: Bastion - ${each.key}"
}

### Bastion Host
resource "aws_security_group_rule" "allow_ingress_on_bastion_kubectl" {
  for_each = {
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Masters"         = aws_security_group.master.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id        = each.value
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  description              = "kubectl: Bastion - ${each.key}"
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-"
  description = "Bastion"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "master-private-lb" {
  name_prefix = "master-private-lb-"
  description = "Master-Private-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-private"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}


### Bastion LB
resource "aws_security_group_rule" "allow_ingress_workstation_on_bastion-lb_ssh" {
  security_group_id = aws_security_group.bastion-lb.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "SSH: Workstation - MasterPublicLB"
}


### MasterPrivateLB
resource "aws_security_group_rule" "allow_ingress_on_master-private-lb_kubeapi" {
  security_group_id = aws_security_group.master-private-lb.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "kubeapi: ALL - MasterPrivateLB"
}

### etcd
resource "aws_security_group_rule" "allow_etcd" {
  for_each = {
    "Masters" = aws_security_group.master.id,
    "Etcd"    = aws_security_group.etcd.id
  }
  security_group_id        = aws_security_group.etcd.id
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "etcd: ${each.key} - Etcds"
}

#aws key pair to generate
resource "aws_key_pair" "ssh" {
  count      = var.aws_key_pair_name == null ? 1 : 0
  key_name   = "${var.owner}-${var.project}"
  public_key = file(var.ssh_public_key_path)
}


# aws load balancer
resource "aws_lb" "lb" {
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.bastion-lb.id]
  subnets            = aws_subnet.private.*.id
  tags = {
    Name    = "${var.project}-lb"
    Project = var.project
    Owner   = var.owner
  }
}
