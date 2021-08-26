variable "siteFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws-main-main/ansible/site.yml"
}
variable "inventoryTemplate" {
    type = string
    default = "/tmp/project/terraform-ansible-aws-main/ansible/staging/inventory.tmpl"
}
variable "inventoryFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws-main/ansible/staging/inventory"
}
variable "indexFilePath" {
    type = string
    default = "/tmp/project/terraform-ansible-aws-main/ansible/roles/common/files/index.html"
}
variable "pub_key" {
    type = string
    default = "/tmp/project/terraform-ansible-aws-main/ansible/roles/common/files/deployer.pub"
}

variable "pvt_key" {
  type = string
  default = "/tmp/project/terraform-ansible-aws-main/ansible/roles/common/files/deployer.pem"
}
