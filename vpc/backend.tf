terraform {
  backend "local" {
    path = "ghost-vpc.tfstate"
  }
}

# The production config will look like this;
# keep empty for backend.hcl features
# terraform {
#     backend "s3 {}
# }