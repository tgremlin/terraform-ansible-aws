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
    default = "/tmp/project/ansible/roles/common/tmp/project/index.html"
}
variable "pub_key" {
    type = string
    default = "/tmp/project/ansible/roles/common/tmp/project/deployer.pub"
}

variable "pvt_key" {
  type = string
  default = "/tmp/project/ansible/roles/common/tmp/project/deployer.pem"
}
