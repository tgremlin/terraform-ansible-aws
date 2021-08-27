# Terraform-Ansible-AWS
This code will deploy an EC2 instance on AWS, with a hello world index page, configured by Ansible.
To run, download or clone repository, and you must update the following values and files:
- **Vars.tf**
  - vpc_cidr: Enter your desired CIDR block, default is 10.0.0.0/16.
  - pub_sub_cidr: Enter the CIDR for the public subnet, default is 10.0.10.0/24.
  - ami_id: Enter an AMI id for the instance.
  - instance_type: Enter an instance size, default is t2.micro.
  - file paths: there are a series of file path variables (siteFilePath, inventoryTemplate, etc) that will need to be updated to fit your environment. You should be able to simply     perform a find a replace for everything left of "terraform-ansible-aws", for example:
    "/home/ubuntu/environment/" > "/home/YOUR_USER/projects"
  - pub_key: Enter a path to a public SSH key (this key will be uploaded to AWS and used to connect to your instance).
  - pvt_key: Enter a path to the private key (must be PEM format). This code will retrieve the key from an AWS secrets manager store (stored as plain text in secrets manager),         using the following code: 
    aws secretsmanager get-secret-value --secret-id YOUR_AWS_SECRET_NAME --query 'SecretString' --output text > /tmp/project/ansible/roles/common/files/deployer.pem
    This retrieves the text value, and saves it to "deployer.pem". This code is found in the config.yml file in the .circleci directory. Feel free to remove this directory if you     are not deploying with a CircleCI pipeline. Just make sure the keys are present in the path stated in the vars.tf file. Also note:
    You must make sure the keys are only accessible to your user, can do so by running "sudo chmod 0400" on your keys.
- **Main.tf**
  - The following block must be updated for your backend options (variables cannot be used in the backend block):
    ```hcl
    # Variables cannot be defined in the backend block, must change to fit your backend method
    backend "s3" {
    bucket = "at-terraform-backends"
    key    = "terraform/learnTerraformAWSInstance/terraform.tfstate"
    region = "us-east-1"
      }
    }
    ```
 
After updatign vars.tf
