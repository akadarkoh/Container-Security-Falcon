package terraform.ecs.pipeline.security

# ============================================================================
# SECURITY GROUP RULES - Lock down open access
# ============================================================================

# Deny security groups with unrestricted inbound access
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port != 443  # Allow HTTPS from anywhere
    rule.from_port != 80   # Allow HTTP from anywhere (consider removing in production)
    msg := sprintf("Security group '%s' allows unrestricted access on port %d from 0.0.0.0/0. Restrict to specific IPs or use ALB.", [resource.address, rule.from_port])
}

# Deny security groups allowing SSH from anywhere
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port == 22
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows SSH access from 0.0.0.0/0. Use bastion host or VPN.", [resource.address])
}

# Deny security groups allowing RDP from anywhere
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port == 3389
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows RDP access from 0.0.0.0/0. Use bastion host or VPN.", [resource.address])
}

# Deny overly permissive security group rules
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port == 0
    rule.to_port == 65535
    msg := sprintf("Security group '%s' allows all ports. Specify exact ports needed.", [resource.address])
}

# ============================================================================
# TAGGING REQUIREMENTS - Establish tag standards
# ============================================================================

# Required tags for all resources
required_tags := {
    "Environment": ["dev", "staging", "prod"],
    "Owner": ".*",  # Any value, but must be present
    "Project": ".*",
    "ManagedBy": ["terraform"]
}

# ECS Cluster tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_cluster"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("ECS Cluster '%s' is missing required tag: %s", [resource.address, tag_name])
}

# ECS Service tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_service"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("ECS Service '%s' is missing required tag: %s", [resource.address, tag_name])
}

# ECS Task Definition tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("ECS Task Definition '%s' is missing required tag: %s", [resource.address, tag_name])
}

# CodePipeline tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_codepipeline"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("CodePipeline '%s' is missing required tag: %s", [resource.address, tag_name])
}

# CodeBuild Project tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_codebuild_project"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("CodeBuild Project '%s' is missing required tag: %s", [resource.address, tag_name])
}

# ECR Repository tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_repository"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("ECR Repository '%s' is missing required tag: %s", [resource.address, tag_name])
}

# ALB/Load Balancer tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    resource.change.actions[_] != "delete"
    tag_name := required_tags[_]
    not resource.change.after.tags[tag_name]
    msg := sprintf("Load Balancer '%s' is missing required tag: %s", [resource.address, tag_name])
}

# ============================================================================
# ECR REPOSITORY SECURITY
# ============================================================================

# Require ECR image scanning
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_repository"
    resource.change.actions[_] == "create"
    not resource.change.after.image_scanning_configuration
    msg := sprintf("ECR Repository '%s' must have image scanning enabled", [resource.address])
}

deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_repository"
    resource.change.actions[_] == "create"
    scanning := resource.change.after.image_scanning_configuration[_]
    scanning.scan_on_push != true
    msg := sprintf("ECR Repository '%s' must have scan_on_push enabled", [resource.address])
}

# Require ECR encryption
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_repository"
    resource.change.actions[_] == "create"
    not resource.change.after.encryption_configuration
    msg := sprintf("ECR Repository '%s' must have encryption enabled", [resource.address])
}

# Require ECR lifecycle policy
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_repository"
    resource.change.actions[_] == "create"
    not has_lifecycle_policy(resource.address)
    msg := sprintf("ECR Repository '%s' should have a lifecycle policy to manage image retention", [resource.address])
}

has_lifecycle_policy(repo_address) if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecr_lifecycle_policy"
    contains(resource.change.after.repository, repo_address)
}

# ============================================================================
# ECS TASK DEFINITION SECURITY
# ============================================================================

# Require task definitions to use execution role
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] == "create"
    not resource.change.after.execution_role_arn
    msg := sprintf("ECS Task Definition '%s' must specify an execution_role_arn", [resource.address])
}

# Require task definitions to use task role (for application permissions)
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] == "create"
    not resource.change.after.task_role_arn
    msg := sprintf("ECS Task Definition '%s' should specify a task_role_arn for application permissions", [resource.address])
}

# Ensure containers don't run as privileged
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_task_definition"
    container := parse_container_definitions(resource.change.after.container_definitions)[_]
    container.privileged == true
    msg := sprintf("ECS Task Definition '%s' contains a privileged container. Avoid privileged mode.", [resource.address])
}

# Check for readonlyRootFilesystem
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_task_definition"
    container := parse_container_definitions(resource.change.after.container_definitions)[_]
    not container.readonlyRootFilesystem
    msg := sprintf("ECS Task Definition '%s' container '%s' should use readonlyRootFilesystem for better security", [resource.address, container.name])
}

# Helper function to parse container definitions
parse_container_definitions(json_string) := result if {
    result := json.unmarshal(json_string)
}

# ============================================================================
# ECS SERVICE SECURITY
# ============================================================================

# Require services to use latest platform version for Fargate
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_service"
    resource.change.after.launch_type == "FARGATE"
    resource.change.after.platform_version != "LATEST"
    msg := sprintf("ECS Service '%s' should use platform_version LATEST for Fargate", [resource.address])
}

# Ensure ECS services have health checks configured
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ecs_service"
    count(resource.change.after.load_balancer) > 0
    not resource.change.after.health_check_grace_period_seconds
    msg := sprintf("ECS Service '%s' with load balancer should configure health_check_grace_period_seconds", [resource.address])
}

# ============================================================================
# CODEBUILD SECURITY
# ============================================================================

# Require CodeBuild to use privileged mode only when necessary
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_codebuild_project"
    environment := resource.change.after.environment[_]
    environment.privileged_mode == true
    msg := sprintf("CodeBuild Project '%s' uses privileged_mode. Only use if Docker-in-Docker is required.", [resource.address])
}

# Ensure CodeBuild uses VPC when accessing private resources
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_codebuild_project"
    not resource.change.after.vpc_config
    msg := sprintf("CodeBuild Project '%s' should use vpc_config if accessing private resources", [resource.address])
}

# Require CodeBuild logs to be encrypted
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_codebuild_project"
    logs := resource.change.after.logs_config[_]
    cloudwatch_logs := logs.cloudwatch_logs[_]
    cloudwatch_logs.status == "ENABLED"
    not cloudwatch_logs.encryption_disabled == false
    msg := sprintf("CodeBuild Project '%s' CloudWatch logs should be encrypted", [resource.address])
}

# ============================================================================
# IAM SECURITY
# ============================================================================

# Prevent overly permissive IAM policies
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_role_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf("IAM Policy '%s' grants overly permissive permissions (Action: *, Resource: *)", [resource.address])
}

# Warn about inline policies (prefer managed policies)
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_role_policy"
    resource.change.actions[_] == "create"
    msg := sprintf("IAM Role Policy '%s' is inline. Consider using managed policies for better reusability.", [resource.address])
}

# ============================================================================
# CLOUDWATCH LOGS
# ============================================================================

# Require log retention to be set
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    not resource.change.after.retention_in_days
    msg := sprintf("CloudWatch Log Group '%s' should have retention_in_days set to manage costs", [resource.address])
}

# Require log encryption
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    resource.change.actions[_] == "create"
    not resource.change.after.kms_key_id
    msg := sprintf("CloudWatch Log Group '%s' should be encrypted with KMS", [resource.address])
}

# ============================================================================
# LOAD BALANCER SECURITY
# ============================================================================

# Require ALB to use HTTPS listeners
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb_listener"
    resource.change.after.protocol == "HTTP"
    msg := sprintf("Load Balancer Listener '%s' uses HTTP. Consider using HTTPS with SSL certificate.", [resource.address])
}

# Ensure ALB has access logs enabled
warn[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    not resource.change.after.access_logs
    msg := sprintf("Load Balancer '%s' should have access_logs enabled for audit trail", [resource.address])
}

# ============================================================================
# POLICY SUMMARY
# ============================================================================

# Count violations
violation_count := count(deny)
warning_count := count(warn)

# Main policy decision - fails if any deny rules are triggered
allow if {
    violation_count == 0
}

# Summary for output
summary := {
    "violations": violation_count,
    "warnings": warning_count,
    "allow": allow
}
