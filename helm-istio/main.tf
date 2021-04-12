# Configuring terraform kubernetes provider with minikube context and pointing to local kube config

locals {
  kube_config = "~/.kube/config"

    helmChartValuesIstio = {
    global = {
      jwtPolicy = "first-party-jwt"
    }
    gateways = {
      istio-ingressgateway = {
        type = "NodePort"
        # nodeSelector = {
        #   ingress-ready = "true"
        # }
        ports = [
          {
            port       = 15021
            targetPort = 15021
            nodePort   = 30002
            name       = "status-port"
            protocol   = "TCP"
          },
          {
            port       = 80
            targetPort = 8080
            nodePort   = 30000
            name       = "http2"
            protocol   = "TCP"
          },
          {
            port       = 443
            targetPort = 8443
            nodePort   = 30001
            name       = "https"
            protocol   = "TCP"
          }
        ]
      }
    }
  }
}
provider "kubernetes" {
  config_context_cluster   = "minikube"
  config_path = local.kube_config
}
provider "helm" {
  kubernetes {
    config_path = local.kube_config
  }
}

###################Install Istio (Service Mesh) #######################################
## https://istio.io/latest/docs/setup/install/helm/


# https://github.com/istio/istio/tree/master/manifests/charts/base
# helm install istio-base manifests/charts/base -n istio-system

resource "helm_release" "istio-base" {
  namespace  = kubernetes_namespace.istio_system.id
  name       = "istio-base"
  chart      = "${path.module}/istio/manifests/charts/base"
  values = [
    yamlencode(local.helmChartValuesIstio)
  ]
}

# helm install istiod manifests/charts/istio-control/istio-discovery -n istio-system

resource "helm_release" "istio-discovery" {
  namespace  = kubernetes_namespace.istio_system.id
  name       = "istio-discovery"
  chart      = "${path.module}/istio/manifests/charts/istio-control/istio-discovery"

  values = [
    yamlencode(local.helmChartValuesIstio)
  ]
  depends_on = [helm_release.istio-base]
}

resource "helm_release" "istio-ingress" {
  name       = "istio-ingress"
  chart      = "${path.module}/istio/manifests/charts/gateways/istio-ingress"
  namespace  = kubernetes_namespace.istio_system.id

  values = [
    yamlencode(local.helmChartValuesIstio)
  ]

  depends_on = [helm_release.istio-base]
}


# Kiali
# https://kiali.io/documentation/latest/quick-start/#_install_via_kiali_server_helm_chart
resource "helm_release" "kiali" {
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  version    = "v1.29.0"

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }
  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-server.istio-system.svc.cluster.local:80"
  }

  namespace = kubernetes_namespace.istio_system.id
  depends_on = [
    kubernetes_namespace.istio_system , helm_release.prometheus
  ]
  wait = true
}

# RUN : istioctl dashboard kiali




# ----------------------------------------------------------------------------------------------------------------------
# prometheus
# ----------------------------------------------------------------------------------------------------------------------
# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }
# }

locals {
  helmChartValuesPrometheus = {
    alertmanager = {
      enabled = false
    }
    pushgateway = {
      enabled = false
    }
    server = {
      persistentVolume = {
        enabled = false
      }
      global = {
        scrape_interval = "15s"
      }
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace = kubernetes_namespace.istio_system.id

  values = [
    yamlencode(local.helmChartValuesPrometheus)
  ]

  depends_on = [
    helm_release.istio-base,
    helm_release.istio-discovery
  ]
}
