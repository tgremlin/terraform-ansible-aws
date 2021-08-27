variable "region" {
    type = string
    default = "us-east-1"
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
variable "all_ip_cidr" {
    type = string
    default = "0.0.0.0/0"
}
variable "ami_id" {
    type = string
    default = "ami-0cc77a21e59868a1a" #Ubuntu 18.04 AMI created with packer that has auto updates disable
}
variable "instance_type" {
    type = string
    default = "t2.micro"
}
variable "siteFilePath" {
    type = string
    default = "/tmp/project/ansible/site.yml"
}
variable "inventoryTemplate" {
    type = string
    default = "/tmp/project/ansible/staging/inventory.tmpl"
}
variable "inventoryFilePath" {
    type = string
    default = "/tmp/project/ansible/staging/inventory"
}
variable "indexFilePath" {
    type = string
    default = "/tmp/project/ansible/roles/common/files/index.html"
}
variable "pub_key" {
    type = string
    default = "/tmp/project/ansible/roles/common/files/deployer.pub"
}

variable "pvt_key" {
  type = string
  default = "/tmp/project/ansible/roles/common/files/deployer.pem"
}
