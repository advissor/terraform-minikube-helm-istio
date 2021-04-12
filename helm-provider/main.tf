# Configuring terraform kubernetes provider with minikube context and pointing to local kube config

provider "kubernetes" {
  config_context_cluster   = "minikube"
  config_path = "~/.kube/config"
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "service.nodePorts.http"
    value = "30201"
  }
  
}




# minikube ip
# Visit : <minikube ip>:30201