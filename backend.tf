terraform {
  backend "s3" {
    bucket         = "my-terraform-state" 
    region         = "ap-northeast-1" 
    key            = "backend/test/terraform.tfstate"
    dynamodb_table = "terraform-lock-table" 
    encrypt        = true                    
  }
}
