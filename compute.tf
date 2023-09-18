## Ubuntu AMI for all  instances
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

## instance Master
resource "aws_launch_configuration" "master" {
  name_prefix                 = "master-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  security_groups             = [aws_security_group.master.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true

}


## instance Worker
resource "aws_launch_configuration" "worker" {
  name_prefix                 = "worker-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  security_groups             = [aws_security_group.worker.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  
}
## Kubernetes Master
resource "aws_instance" "master" {
  count = 1
  ami = data.aws_ami.ubuntu.id
  instance_type = "${var.master_instance_type}"
  tags = {
    Name = "${var.project}-taw-master-${count.index}"
  }
  provisioner "file" {
    source      = "./playbook.yaml"
    destination = "./playbook.yaml"
  }
  provisioner "file"{
    source      = "./hosts.ini"
    destination = "/hosts.ini"
  }
  provisioner "file" {
    source      = "./install.sh"
    destination = "./install.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod +x ./install.sh",
      "./install.sh",
     ]
  }
}
  
## Kubernetes Worker
resource "aws_instance" "worker" {
  count = 2
  ami = data.aws_ami.ubuntu.id
  instance_type = "${var.worker_instance_type}"
  tags = {
    Name = "${var.project}-taw-worker-${count.index}"
  }
    provisioner "file" {
    source      = "./playbook.yaml"
    destination = "./playbook.yaml"
  }
  provisioner "file"{
    source      = "./hosts.ini"
    destination = "/hosts.ini"
  }
  provisioner "file" {
    source      = "./install.sh"
    destination = "./install.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /home/ubuntu/install.sh",
      "/home/ubuntu/install.sh",
     ]
  }
}