variable "siteFilePath" {
    type = string
    default = "/files/ansible/site.yml"
}
variable "inventoryTemplate" {
    type = string
    default = "/files/ansible/staging/inventory.tmpl"
}
variable "inventoryFilePath" {
    type = string
    default = "/files/ansible/staging/inventory"
}
variable "indexFilePath" {
    type = string
    default = "/files/ansible/roles/common/files/index.html"
}
variable "pub_key" {
    type = string
    default = "/files/ansible/roles/common/files/deployer.pub"
}

variable "pvt_key" {
  type = string
  default = "/files/ansible/roles/common/files/deployer.pem"
}
