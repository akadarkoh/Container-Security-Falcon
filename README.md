# Container-Security-Falcon

This project will be about how we secure containers in the cloud before deployment. The container will be stored inside ECR. We will use ECS to write tasks that should be executed before deployment. We will make use of codepipeline to automate the deployment process.

## System Design:

![System Design](system_design/falcon.png)

## Folder structure:

## Installation:

### Terraform Commands:

To deploy this infrastructure using Terraform, execute the following commands in order:

1.  **Initialize Terraform:**

    ```bash
    terraform init
    ```

2.  **Review the Planned Changes:**

    ```bash
    terraform plan
    ```

3.  **Apply the Configuration:**
    ```bash
    terraform apply
    ```

## Image push

Step 1: build your docker image
`docker build -t <id-number>.dkr.ecr.us-east-1.amazonaws.com/box-office-repo:latest .`

Step 2: login to ECR
`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <iamnumber></iamnumber>.dkr.ecr.us-east-1.amazonaws.com`
Step 3: push your image to ECR
`docker push <id-number>.dkr.ecr.us-east-1.amazonaws.com/box-office-repo:latest`

## Contact us:

```

```
