#### The ansible inventory file
resource "local_file" "AnsibleInventory" {
  content = templatefile("/home/ubuntu/terraform_projects/learn-terraform-aws-instance/ansible/staging/inventory.tmpl",
  {
    bastion-dns = aws_eip.eip-bastion.public_dns,
    bastion-ip  = aws_eip.eip-bastion.public_ip,
    bastion-id  = aws_instance.bastion.id
  }
  )
  filename = "/home/ubuntu/terraform_projects/learn-terraform-aws-instance/ansible/staging/inventory"
}

