This is a spec that you should use to implement a project

**Required Services**

- Amazon ECR: Stores images and emits image push events.
- AWS CodePipeline: Orchestrates the workflow.
- AWS CodeBuild: Runs Docker/CLI to pull and process the image.
- Amazon S3: Artifact store for CodePipeline.
- AWS IAM: Roles for CodePipeline and CodeBuild with ECR permissions.
- CloudWatch Logs: Build/pipeline logs.
- Optional: AWS KMS (encrypt artifacts), EventBridge (under the hood for triggers), CodeDeploy (blue/green ECS), ECS/EKS (if deploying), SNS/Chatbot (notifications), Systems Manager Parameter Store/Secrets Manager (extra secrets).

**Implementation Steps**

- Create ECR repo: Enable vulnerability scanning if desired.
- Create S3 artifact bucket: For CodePipeline artifacts.
- Create CodeBuild project:
  - Environment: Managed image with Docker, enable “Privileged” mode for Docker-in-Docker.
  - Service role: Allow `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, and `logs:*`, `s3:*` (scoped to needed resources).
- Create CodePipeline:
  - Source action: Provider “Amazon ECR”, select repo and tag (or `latest`), output `imageDetail.json`.
  - Build action: Your CodeBuild project consumes the source artifact.
  - Optional deploy stage: ECS/CodeDeploy action, or a second CodeBuild that runs `kubectl` for EKS.
- Grant IAM:
  - CodePipeline role: Access to S3 artifact bucket, invoke CodeBuild, read the ECR source artifact.
  - CodeBuild role: ECR read (and write if needed), S3 artifact read/write, Logs write, KMS decrypt if used.
- Networking: If ECR access is via VPC endpoints, place CodeBuild in a VPC with needed endpoints (`com.amazonaws.<region>.ecr.api`, `ecr.dkr`, `s3`, `logs`).

**Sample buildspec (pull + inspect)**

- File: `buildspec.yml` for the CodeBuild action.
- What it does: Reads `imageDetail.json` from the ECR source, logs into ECR, pulls image, inspects manifest/labels. You can extend with Trivy or tests.

- version: 0.2
  phases:
  pre_build:
  commands: - echo "Reading image details from source artifact" - IMAGE_URI=$(jq -r '.ImageURI' imageDetail.json)
        - REPO=$(jq -r '.RepositoryName' imageDetail.json) - TAG=$(jq -r '.ImageTag' imageDetail.json)
        - ACCOUNT_ID=$(echo "$IMAGE_URI" | cut -d'.' -f1)
        - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
  build:
  commands: - echo "Pulling $IMAGE_URI"
        - docker pull "$IMAGE_URI" - echo "Docker inspect" - docker inspect "$IMAGE_URI" | tee docker_inspect.json
        - echo "ECR manifest"
        - aws ecr batch-get-image --repository-name "$REPO" --image-ids imageTag="$TAG" --query 'images[0].imageManifest' --output text | jq '.' | tee ecr_manifest.json
        # Example: run a security scan (if Trivy preinstalled or installed at runtime)
        # - trivy image --exit-code 0 --format json -o trivy.json "$IMAGE_URI"
  artifacts:
  files: - imageDetail.json - docker_inspect.json - ecr_manifest.json # - trivy.json

**Deploy Options**

- ECS Standard: Add a CodePipeline “ECS deploy” action targeting a service/task definition that uses the new image tag or digest.
- ECS Blue/Green: Use CodeDeploy with ECS provider for traffic shifting and health checks.
- EKS: Add a CodeBuild action that runs `kubectl set image ...` or `helm upgrade ...`. Provide cluster auth via IAM Role for Service Accounts (IRSA) or kubeconfig in Parameter Store/Secrets Manager.

**IAM Policy Tips**

- CodeBuild role needs:
  - `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, `ecr:DescribeImages`
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
  - `s3:GetObject`, `s3:PutObject` on the artifact bucket/path
- CodePipeline role needs:
  - `codebuild:StartBuild`, `codebuild:BatchGetBuilds`
  - `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` for artifact bucket
  - Optional deploy permissions for ECS/CodeDeploy

**Quick Start (Console)**

- Create S3 artifact bucket and KMS key (optional).
- Use ECR repo, push a test image, and enable scan.
- Create a CodeBuild project with Docker privileged mode; attach the IAM role.
- In CodePipeline:
  - Source = Amazon ECR (select repo + tag).
  - Build = your CodeBuild project with the `buildspec.yml`.
  - Optional deploy = ECS or CodeDeploy.
- Push a new image/tag to ECR to trigger the pipeline.
