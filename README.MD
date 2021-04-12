Terraform kubernetes provider with minikube

# Prerequisites

 - terraform
 - minikube 
 - kubectl 

# Example 1 : Creating namespaces on local minikube cluster via terraform

cd namespaces 

minikube start
terraform init
terraform apply


# Example 2 : Deploying sample hello world app on local minikube cluster via terraform

minikube start

terraform apply