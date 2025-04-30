terraform {
  backend "s3" {
    bucket       = "degen-dr-primary-bucket-pilot-light"
    key          = "terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}