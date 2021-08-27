# Terraform-Ansible-AWS
This code will deploy an EC2 instance on AWS, with a hello world index page, configured by Ansible.
To run, download or clone repostiory, and you must update the following values and files:
- Var.tf
  - vpc_cidr: Enter your desired CIDR block, default is 10.0.0.0/16.
  - pub_sub_cidr: Enter the CIDR for the public subnet, default is 10.0.10.0/24.
  - ami_id: Enter an AMI id for the instance.
  - instance_type: Enter an instance size, default is t2.micro.
  - file paths: there are a series of file path variables (siteFilePath, inventoryTemplate, etc) that will need to be updated to fit your environment. You should be able to simply     perform a find a replace for everything left of "terraform-ansible-aws", for example:
    "/home/ubuntu/environment/" > "/home/YOUR_USER/projects"
  - pub_key: Enter a path to a public SSH key (this key will be uploaded to AWS and used to connect to your instance).
  - pvt_key: Enter a path to the private key (must be PEM format).
