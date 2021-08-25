variable "siteFilePath" {
    type = string
    default = "/home/ubuntu/environment/learnTerraformAWSInstance/ansible/site.yml"
}
variable "inventoryFilePath" {
    type = string
    default = "/home/ubuntu/environment/learnTerraformAWSInstance/ansible/staging/inventory"
}
variable "indexFilePath" {
    type = string
    default = "/home/ubuntu/environment/learnTerraformAWSInstance/ansible/roles/common/files/index.html"
}
variable "localPath" {
    type = string
    default = "/home/ubuntu/environment/"
}