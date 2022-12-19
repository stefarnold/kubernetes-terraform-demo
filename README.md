# Kubernetes Multi-AZ cluster Demo

This project builds a VPC with a public and private subnet for each available availability zone. Then it creates an EKS cluster with nodes spread across each private subnet. A basic Bitnami Ghost Helm chart is deployed onto the cluster to demonstrate that traffic flows to services as expected, when a load balancer is launched in a public subnet. 

## Instructions

```
cd vpc
terraform init
terraform apply -var-file tfvars/poc.tfvars
cd ../cluster
terraform init
# todo: fix k8s provider manual step
terraform apply -var-file tfvars/poc.tfvars
```

Once the cluster is up and the helm release is ready, you can hit the Ghost demo page by hitting the ELB public DNS name. 
ToDo: Route53
