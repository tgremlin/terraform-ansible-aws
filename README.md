# Terraform-Ansible-AWS
This code will deploy an EC2 instance on AWS, with a hello world index page, configured by Ansible.
To run, download or clone repository, and you must update the following values and files:
- **Vars.tf**
  - region: Enter an AWS region, default is us-east-1
  - vpc_cidr: Enter your desired CIDR block, default is 10.0.0.0/16.
  - pub_sub_cidr: Enter the CIDR for the public subnet, default is 10.0.10.0/24.
  - ami_id: Enter an AMI id for the instance.
  - instance_type: Enter an instance size, default is t2.micro.
  - file paths: there are a series of file path variables (siteFilePath, inventoryTemplate, etc) that will need to be updated to fit your environment. You should be able to simply     perform a find a replace for everything left of "terraform-ansible-aws", for example:
    "/home/ubuntu/environment/" > "/home/YOUR_USER/projects"
  - pub_key: Enter a path to a public SSH key (this key will be uploaded to AWS and used to connect to your instance).
  - pvt_key: Enter a path to the private key (must be PEM format). This code will retrieve the key from an AWS secrets manager store (stored as plain text in secrets manager),         using the following code: 
    ```yaml
    aws secretsmanager get-secret-value --secret-id YOUR_AWS_SECRET_NAME --query 'SecretString' --output text > /tmp/project/ansible/roles/common/files/deployer.pem
    ```
    This retrieves the text value and saves it to "deployer.pem". This code is found in the config.yml file in the .circleci directory. Feel free to remove this directory if you     are not deploying with a CircleCI pipeline. Just make sure the keys are present in the path stated in the vars.tf file. Also note:
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
 
After updating of vars.tf and main.tf, the following code in site.yml should be updated for your descired username:
  ```yaml
    - name: Add the user 'gremlin' and add it to 'sudo'
      user:
        name: gremlin
        group: sudo
    - name: Add SSH key to 'gremlin'
      authorized_key:
        user: gremlin
        key: "{{ lookup('file', pub_key ) }}"
  ```

The Ansible inventory file is dynamically generated using the following code from main.tf and inventory.tmpl (found in ansible-->roles-->common-->files):
```yaml
#### The ansible inventory file #########
## These values will be used to create ##
## a dynamic ansible inventory file    ##
## populated with values from the new  ##
## EC2 instance                        ##
resource "local_file" "AnsibleInventory" {
  content = templatefile("${var.inventoryTemplate}",
    {
      bastion-dns = aws_eip.eip-bastion.public_dns,
      bastion-ip  = aws_eip.eip-bastion.public_ip,
      bastion-id  = aws_instance.bastion.id
    }
  )
  filename = "var.inventoryFilePath"
}
```
These variable values are gathered from the newly created EC2 instance, and the inventory file is created in the path from the inventoryFilePath variable. The inventory.tmpl code looks like this:
```
[bastion]
${bastion-dns} asnible_host=${bastion-ip} # ${bastion-id}
```
If you change the name of the EC2 instance, you must update it here as well. 

# CircleCI Deployments

If you plan to use CircleCI to deploy this terraform project, you must update the following CircleCI environment variables:
```yaml
    steps:
      - checkout
      - run:
          name: run AWS configure
          command: |
            aws configure --profile staging set region $AWS_DEFAULT_REGION
            aws configure --profile staging set access_key $AWS_ACCESS_KEY_ID
            aws configure --profile staging set secret_key $AWS_SECRET_ACCESS_KEY  
```
$AWS_DEFAULT_REGION = your desired default region (us-east-1)
$AWS_ACCESS_KEY_ID = your aws access key for the user who this code will run as
$AWS_SECRET_ACCESS_KEY = your aws secret access key
These values will be masked in all the CircleCI outputs as long as you use environment varialbes, **DO NOT STORE THESE VALUES IN PLAIN TEXT!!!!**

This project also uses a custom docker image with all the dependencies to execute this terraform script:

```yaml
    docker:
      - image: tgremlin82/terraform_ansible_aws:1.0
```
The docker image is built using a CircleCI pipeline, the code can be viewed [here](https://github.com/tgremlin/terraform-ansible-docker)

**Terraform Approval CircleCI workflow**
This workflow has 3 phases,each phase first generates a terraform plan and saves the file to:
- tfapply
- tfdestroy
You will see that CircleCI has two workflows for each phase:
- plan-apply
- apply
- plan-destroy
- destroy
After each plan phase, a manual code review and approval is required in the CircleCI UI. See the config.yml:
```yaml
version: 2

jobs:
  plan-apply:
    working_directory: /tmp/project
    docker:
      - image: tgremlin82/terraform_ansible_aws:1.0
    steps:
      - checkout
      - run:
          name: run AWS configure
          command: |
            aws configure --profile staging set region $AWS_DEFAULT_REGION
            aws configure --profile staging set access_key $AWS_ACCESS_KEY_ID
            aws configure --profile staging set secret_key $AWS_SECRET_ACCESS_KEY  
      - run:
          name: save AWS secrets ssh private key to file
          command: |
            aws secretsmanager get-secret-value --secret-id $AWS_SECRET_SSH --query 'SecretString' --output text > /tmp/project/ansible/roles/common/files/deployer.pem             
      - run:
          name: terraform init & plan
          command: |
            pwd
            terraform init -input=false
            terraform plan -out tfapply
      - persist_to_workspace:
          root: .
          paths:
            - .

  apply:   
    working_directory: /tmp/project  
    docker:
      - image: tgremlin82/terraform_ansible_aws:1.0
    steps:
      - attach_workspace:
          at: /tmp/project
      - run:
          name: terraform
          command: |
            terraform apply -auto-approve tfapply
      - persist_to_workspace:
          root: .
          paths:
            - .

  plan-destroy: 
    working_directory: /tmp/project
    docker:
      - image: tgremlin82/terraform_ansible_aws:1.0
    steps:
      - attach_workspace:
          at: /tmp/project
      - run:
          name: terraform create destroy plan
          command: |
            terraform plan -destroy -out tfdestroy
      - persist_to_workspace:
          root: .
          paths:
            - .

  destroy:
    working_directory: /tmp/project
    docker:
      - image: tgremlin82/terraform_ansible_aws:1.0
    steps:
      - attach_workspace:
          at: /tmp/project
      - run:
          name: terraform destroy
          command: |
            terraform apply -auto-approve tfdestroy
workflows:
  version: 2
  plan_approve_apply:
    jobs:
      - plan-apply
      - hold-apply:
          type: approval
          requires:
            - plan-apply
      - apply:
          requires:
            - hold-apply
      - plan-destroy:
          requires:
            - apply
      - hold-destroy:
          type: approval
          requires:
            - plan-destroy
      - destroy:
          requires:
            - hold-destroy
```
See screenshots below of approval process:
![Hold Apply](https://github.com/tgremlin/terraform-ansible-aws/blob/main/hold_apply.PNG)

![Hold Approve](https://github.com/tgremlin/terraform-ansible-aws/blob/main/approve_apply.PNG)
# To Do

- [ ] Optomize docker image size
- [ ] Add a slack channel notification when CircleCI is in a hold state
- [ ] Add a slack channel notification when CircleCI workflows fail
