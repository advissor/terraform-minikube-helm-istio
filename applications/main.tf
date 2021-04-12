# Configuring terraform kubernetes provider with minikube context and pointing to local kube config

provider "kubernetes" {
  config_context_cluster   = "minikube"
  config_path = "~/.kube/config"
}

# Creating namespaces

resource "kubernetes_namespace" "applications-namespace" {
  metadata {
        name = "applications"
  }
}

resource "kubernetes_namespace" "monitoring-namespace" {
  metadata {
        name = "monitoring"
  }
}



# Deploying apps 
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment

# Deployment

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    namespace = kubernetes_namespace.applications-namespace.id
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


#  Service





resource "kubernetes_service" "nginx-svc" {
  metadata {
    name = "nginx-example"
    namespace = kubernetes_namespace.applications-namespace.id
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

# minikube ip
# Visit : <minikube ip>:30201