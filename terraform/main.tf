terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "core" {
  name = var.core_resource_group
}

data "azurerm_container_app_environment" "env" {
  name                = var.core_env_name
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_container_registry" "acr" {
  name                = var.core_acr_name
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_postgresql_flexible_server" "postgres" {
  name                = var.core_postgres_name
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_user_assigned_identity" "aca_identity" {
  name                = "aca-identity"
  resource_group_name = data.azurerm_resource_group.core.name
}

resource "azurerm_container_app" "odoo" {
  name                         = "odoo-app"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name         = data.azurerm_resource_group.core.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = data.azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = 8069
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "odoo"
      image  = "${data.azurerm_container_registry.acr.login_server}/odoo:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"
      args   = ["--db-filter=^odoo$"]

      env {
        name  = "HOST"
        value = data.azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "PORT"
        value = "6432" # PgBouncer — avoids connection exhaustion under load
      }
      env {
        name  = "USER"
        value = var.db_user
      }
      env {
        name  = "PASSWORD"
        value = var.db_password
      }

      volume_mounts {
        name = "odoo-volume"
        path = "/var/lib/odoo"
      }

      readiness_probe {
        port      = 8069
        transport = "HTTP"
        path      = "/"
        interval_seconds    = 5
        failure_count_threshold = 1
      }

      liveness_probe {
        port      = 8069
        transport = "HTTP"
        path      = "/"
        interval_seconds    = 5
        failure_count_threshold = 3
      }
    }

    volume {
      name         = "odoo-volume"
      storage_name = "odoo-storage" 
      storage_type = "AzureFile"
    }

    min_replicas = 0
    max_replicas = 5

  }
}
