resource "aws_codebuild_project" "falcon_codebuild_project" {
  name          = "falcon-codebuild-project"
  description   = "CodeBuild project for Falcon container security"
  build_timeout = "15"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    # Docker-in-Docker required for building and scanning container images
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = data.aws_ecr_repository.falcon_ecr_repository.name
    }

    environment_variable {
      name  = "AWS_REGION"
      value  = var.region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      env:
        variables:
          TRIVY_VERSION: "0.49.1"
      phases:
        install:
          commands:
            - echo "Installing Trivy $TRIVY_VERSION..."
            - curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v$TRIVY_VERSION
        pre_build:
          commands:
            - echo "Logging into Amazon ECR..."
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
            - export REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME
            - export COMMIT_HASH=$$(echo $$CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
            - export IMAGE_TAG=$${COMMIT_HASH:-latest}
        build:
          commands:
            - echo "Building Docker image..."
            - docker build -t $$REPOSITORY_URI:latest -t $$REPOSITORY_URI:$$IMAGE_TAG .
            - echo "Running Trivy scan..."
            - trivy image --exit-code 0 --format json -o trivy.json $$REPOSITORY_URI:latest
        post_build:
          commands:
            - echo "Pushing Docker image to ECR..."
            - docker push $$REPOSITORY_URI:latest
            - docker push $$REPOSITORY_URI:$$IMAGE_TAG
            - echo "Creating imagedefinitions.json..."
            - printf '[{"name":"falcon-app","imageUri":"%s"}]' $$REPOSITORY_URI:latest > imagedefinitions.json
            - cat imagedefinitions.json
      artifacts:
        files:
          - imagedefinitions.json
          - trivy.json
    EOT
  }

  tags = {
    Name = "falcon-codebuild-project"
  }
}
