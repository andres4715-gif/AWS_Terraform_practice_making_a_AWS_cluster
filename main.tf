terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "~> 2.23"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24","10.0.103.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "demo-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

eks_managed_node_groups = {
  default = {
    instance_types = ["t3.micro"]
    desired_size   = 1
    min_size       = 1
    max_size       = 2
  }
}

  # Opcional: habilitar addons comunes
  cluster_addons = {
    coredns            = {}
    kube-proxy         = {}
    vpc-cni            = {}
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "cluster_ca" {
  value = module.eks.cluster_certificate_authority_data
}

# Kubernetes provider para interactuar con el cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "default"]
    command     = "aws"
  }
}

# Despliegue de la aplicación cronómetro
resource "kubernetes_deployment" "timer_app" {
  metadata {
    name = "timer-app"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "timer-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "timer-app"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "timer"
          
          # Configuramos un volumen para el HTML del cronómetro
          volume_mount {
            name       = "timer-html"
            mount_path = "/usr/share/nginx/html"
          }
        }
        
        # Definimos el contenido HTML como un ConfigMap
        volume {
          name = "timer-html"
          config_map {
            name = kubernetes_config_map.timer_html.metadata[0].name
          }
        }
      }
    }
  }
}

# ConfigMap con el HTML del cronómetro
resource "kubernetes_config_map" "timer_html" {
  metadata {
    name = "timer-html"
  }

  data = {
    "index.html" = <<-EOF
      <!DOCTYPE html>
      <html>
      <head>
        <title>Simple Timer</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
          #timer { font-size: 72px; margin: 20px; }
          button { padding: 10px 20px; margin: 5px; font-size: 16px; }
        </style>
      </head>
      <body>
        <h1>Simple Timer</h1>
        <div id="timer">00:00:00</div>
        <button onclick="startTimer()">Start</button>
        <button onclick="stopTimer()">Stop</button>
        <button onclick="resetTimer()">Reset</button>
        
        <script>
          let seconds = 0;
          let minutes = 0;
          let hours = 0;
          let intervalId;
          
          function updateDisplay() {
            document.getElementById('timer').textContent = 
              (hours < 10 ? '0' + hours : hours) + ':' +
              (minutes < 10 ? '0' + minutes : minutes) + ':' +
              (seconds < 10 ? '0' + seconds : seconds);
          }
          
          function startTimer() {
            if (!intervalId) {
              intervalId = setInterval(() => {
                seconds++;
                if (seconds >= 60) {
                  seconds = 0;
                  minutes++;
                  if (minutes >= 60) {
                    minutes = 0;
                    hours++;
                  }
                }
                updateDisplay();
              }, 1000);
            }
          }
          
          function stopTimer() {
            clearInterval(intervalId);
            intervalId = null;
          }
          
          function resetTimer() {
            stopTimer();
            seconds = 0;
            minutes = 0;
            hours = 0;
            updateDisplay();
          }
        </script>
      </body>
      </html>
    EOF
  }
}

# Servicio para exponer la aplicación
resource "kubernetes_service" "timer_service" {
  metadata {
    name = "timer-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.timer_app.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

# Output para mostrar la URL de acceso
output "timer_app_url" {
  value = "http://${kubernetes_service.timer_service.status[0].load_balancer[0].ingress[0].hostname}"
}