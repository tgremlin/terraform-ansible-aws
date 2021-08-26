variable "siteFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws/ansible/site.yml"
}
variable "inventoryFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws/ansible/staging/inventory"
}
variable "indexFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws/ansible/roles/common/files/index.html"
}
variable "localPath" {
    type = string
    default = "/tmp/project"
}

variable "pub_key" {
    type = string
    default = "/tmp/project/terraform-ansible-aws/ansible/roles/common/files/deployer.pub"
}

variable "pub_key_path" {
  type = string
  default = "/tmp/project/terraform-ansible-aws/ansible/roles/common/files/"
}

variable "pvt_key" {
  type = string
  default = data.aws_secretsmanager_secret.ssh_priv.secret_string
}