terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  backend "s3" {
    bucket = "at-terraform-backends"
    key    = "terraform/learnTerraformAWSInstance/terraform.tfstate"
    region = "us-east-1"
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "bastion" {
  ami           = "ami-0d7144c36249641c2"
  instance_type = "t2.micro"

  tags = {
    Name = var.instance_name
}
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]
    
    connection {
      host	= self.ipv4_address
      type	= "ssh"
      user	= "root"
      private_key = file(var.pvt_key)
}
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' site.yml"

### The EIP for the bastion host
resource "aws_eip" "eip-bastion" {
  vpc = true
  instance = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip

  tags = {
    Name = "bastion"
 }
}

