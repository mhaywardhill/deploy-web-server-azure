### Date created
3rd November 2020

## Project Title
Deploy Web Server in Azure

## Description
This project deploys a Apache website with a load balancer using infrastructure-as-code (Iac).

We use Packer to create an Ubuntu server image, and then use Terraform to deploy the infrastructure to Azure.

To create the Ubuntu server image using Packer, follow the steps below:

* Ensure the resource group "packerimages" exists (the resource group can be changed by editing the JSON file)
* Create and Deploy virtual machine Image to Azure using Packer. 
Set the client_id,client_secret and tenant_id as environment variables or copy them into a file say packer-vars.json and run the following command to create and deploy your image to azure. `packer build -var-file packer-vars.json server.json`

To deploy the infrastructure, follow the steps below:

* Run `terraform init`
* Then run `terraform plan`
* And finally `terraform apply`, typing "yes" when prompted

Some aspects of the deployed can be customised by changing the variables in the vars.tf file. (see list below).

- _prefix_: this is used to prefix all the resources created in Azure
- _location_: this is the region where the resources will be deployed
- _user_: the admin user login name for each virtual machine
- _password_: the password for the above login
- _numofservers_: this is the number of virtual machines to be deployed 
- _project_: this string populates the project tag on each resource