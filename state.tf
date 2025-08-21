terraform {
  backend "s3" {
    bucket         = "my-27-state-bucket"
    key            = "global/s3/falcon.tfstate" # Customize this path if needed
    region         = "us-east-1"                # Change to your AWS region
    dynamodb_table = "terraform-lock-table"     # Optional: For state locking (create this table first)
    encrypt        = true                       # Optional: Enables server-side encryption
  }
}
