terraform {
  backend "local" {
    path = "ghost-helm.tfstate"
  }
}

# The production config will look like this;
# keep empty for backend.hcl features
# terraform {
#     backend "s3 {}
# }