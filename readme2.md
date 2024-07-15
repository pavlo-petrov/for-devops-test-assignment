Install wordpress

Schema of installation




 
Part #1. Manuel setup

step 1.1
Create AWS account 

Step 1.2.
Create S3 bucket for terraform state
(we need to use some database like dynamodb for protacted of using two teraform at one time .. but not realise this )

Step 1.3 
Setup secrets in github and add AWS credential 

Step 1.4. 
Use AWS consule and setup credential for:
- docker hub;
- daatabase/wp-admin; ( i know we need to setup here usernames for db and wordpress .. but maybe in other time )

Step 1.3. 
Create ssh-key for ec2 instance 
(i know we need to use terraform for this - but i had it and don't want to change every time whan i need to run terraform destroy.. )


Part #2. Terraform 
terraform init 
terraform apply 

(I don't know how to run terraform in CI/CD (do you remember - im only junior) - because this we need to run on your/my local machine.)

Part #3. CI/CD

Step 3.1 
Create a docker container with wordpress's source code and push it to dockerhub.
We need use docker for isolate our site. it gives to us better migration in future. 

Step 3.2
Create ami image. 

I used blank-wordpress-code in github repository (only unzip archive from wordpress.org) 
I don't know how wordpress will works if we setup it untile ci/cd - because it will work without connection to databases: mysql and redis... Because this we need to run inside AWS. 
Inside work subnet. 

For this we use script: /packer/scripts/install_wordpress.md
(I needed to ask developers for this.. but i hadn't one whan i started word on this test)

Use instalation script for install wordpress:
- setup database
- setup redis
- setup https plugin (no-realise - HTTPS doesn't word correct for now. im working on this)
- setup S3 (no-realise for now .. maybe untile 1-2 days)
(i know we can use source code with installed plug-ins and but i don't how i will word if we didn't setup it in )

Step 3.3.
Deploy 
We need to use green/blue deploy for change our running instances in ASG.