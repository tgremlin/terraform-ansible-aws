terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
  # Variables cannot be defined in the backend block, must change to fit your backend method
  backend "s3" {
  bucket = "at-terraform-backends"
  key    = "terraform/learnTerraformAWSInstance/terraform.tfstate"
  region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}
# Creates the key pair in AWS used for SSH into instance
resource "aws_key_pair" "instance_ssh" {
  key_name = "deployer-key"
  public_key = file(var.pub_key)
}

# VPC for new environment
resource "aws_vpc" "ansible_test" {
  cidr_block  = var.vpc_cidr
  tags = {
    Name = "ansible_test_vpc"
  }
}
# Security group to allow http and ssh from desicred CIDR block
resource "aws_security_group" "ssh" {
  name_prefix = "ssh"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.ansible_test.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all_ip_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks  = [var.all_ip_cidr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.all_ip_cidr]
  }
  egress {
    from_port  = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.all_ip_cidr]
  }
  egress {
    from_port =  443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.all_ip_cidr]
  }
}
# Internet Gateway
resource "aws_internet_gateway" "ansible_test_igw" {
  vpc_id  = aws_vpc.ansible_test.id
  tags    = {
    Name = "main"
  }
}

# Subnets : Public
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.ansible_test.id
  cidr_block = var.pub_sub_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-public-ansible_test"
  }
}

# Route attache IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ansible_test.id
  route {
    cidr_block = var.all_ip_cidr
    gateway_id = aws_internet_gateway.ansible_test_igw.id
  }
  tags = {
    Name = "publicRouteTable"
  }
}

# associate RT with public subnet
resource "aws_route_table_association" "pub_association" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
# EC2 instance in public subnet
resource "aws_instance" "bastion" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name  = aws_key_pair.instance_ssh.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]
  subnet_id = aws_subnet.public.id

  tags = {
    Name = var.instance_name
  }
# Here we run a remote execution on EC2 instance to ensure the instance
# is created and running before we try and execute the ansible playbook
  provisioner "remote-exec" {
      inline = ["sudo apt-get update", "sudo apt-get install python3 -y" ,"echo Done!"]

      connection {
          host          = self.public_ip
          type          = "ssh"
          user          = "ubuntu"
          private_key   = file(var.pvt_key)
      }
  }
# Disabling ANSIBLE_HOST_KEY_CHECKING skips checking if server was connected beforehand
  provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' -e 'indexFilePath=${var.indexFilePath}' ${var.siteFilePath}"
  }

}

  ### The EIP for the bastion host
resource "aws_eip" "eip-bastion" {
  vpc                       = true
  instance                  = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip

  tags = {
    Name = "bastion"
    }
  }

#### The ansible inventory file #########
## These values will be used to create ##
## a dynamic ansible inventory file    ##
## populated with values from the new  ##
## EC2 instance                        ##
resource "local_file" "AnsibleInventory" {
  content = templatefile("${var.inventoryTemplate}",
    {
      bastion-dns = aws_eip.eip-bastion.public_dns,
      bastion-ip  = aws_eip.eip-bastion.public_ip,
      bastion-id  = aws_instance.bastion.id
    }
  )
  filename = "var.inventoryFilePath"
}