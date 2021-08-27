terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
  
  backend "s3" {
  bucket = "at-terraform-backends"
  key    = "terraform/learnTerraformAWSInstance/terraform.tfstate"
  region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

variable "instance_name" {
  description   = "Value of the name tag for the EC2 instance"
  type          = string
  default       = "Bastion"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "pub_sub_cidr" {
  default = "10.0.10.0/24"
}
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

resource "aws_security_group" "ssh" {
  name_prefix = "ssh"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.ansible_test.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port  = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port =  443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    cidr_block = "0.0.0.0/0"
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

resource "aws_instance" "bastion" {
  ami = "ami-0cc77a21e59868a1a"
  instance_type = "t2.micro"
  key_name  = aws_key_pair.instance_ssh.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]
  subnet_id = aws_subnet.public.id

  tags = {
    Name = var.instance_name
  }

  provisioner "remote-exec" {
      inline = ["sudo apt update", "sudo apt install python3 -y" ,"echo Done!"]

      connection {
          host          = self.public_ip
          type          = "ssh"
          user          = "ubuntu"
          private_key   = file(var.pvt_key)
      }
  }

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

#### The ansible inventory file
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