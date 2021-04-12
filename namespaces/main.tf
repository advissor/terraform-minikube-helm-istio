provider "kubernetes" {
  config_context_cluster   = "minikube"
  config_path = "~/.kube/config"
}


resource "kubernetes_namespace" "applications-namespace" {
  metadata {
        name = "applications-namespace"
  }
}

resource "kubernetes_namespace" "monitoring-namespace" {
  metadata {
        name = "monitoring-namespace"
  }
}