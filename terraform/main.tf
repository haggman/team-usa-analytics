# =============================================================================
# Team USA Analytics — Infrastructure
# =============================================================================
# This Terraform configuration provisions the AlloyDB cluster and supporting
# infrastructure for the Team USA Analytics lab. AlloyDB serves as the vector
# database for semantic athlete similarity search (Task 4).
#
# What's created:
#   - Google Cloud APIs (AlloyDB, BigQuery, Vertex AI, Colab, and more)
#   - VPC networking with Private Service Access (required by AlloyDB)
#   - AlloyDB cluster with a primary instance (public IP, IAM auth)
#   - IAM user registration so you can connect without a password
#
# You don't need to modify this file — just update terraform.tfvars with
# your lab-specific values, then apply.
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.17.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {
  project_id = var.project_id
}

# -----------------------------------------------------------------------------
# Enable Required APIs
# -----------------------------------------------------------------------------
# We enable all APIs upfront so they're ready when each task needs them.

locals {
  required_apis = [
    # AlloyDB & networking
    "alloydb.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",

    # AI & ML
    "aiplatform.googleapis.com",

    # BigQuery
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",

    # Colab Enterprise
    "notebooks.googleapis.com",
    "dataform.googleapis.com",

    # Gemini Cloud Assist
    "cloudaicompanion.googleapis.com",

    # Core platform
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",

    # Model Armor (AI guardrails)
    "modelarmor.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each           = toset(local.required_apis)
  service            = each.value
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
# AlloyDB is a VPC-native service — every cluster lives inside a VPC.

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.main.id
  region        = var.region
}

# -----------------------------------------------------------------------------
# Private Service Access
# -----------------------------------------------------------------------------
# AlloyDB uses PSA to securely connect to Google's managed services.
# This allocates a private IP range and creates the peering connection.

resource "google_compute_global_address" "private_ip_range" {
  name          = "team-usa-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.main.id

  depends_on = [google_project_service.apis]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  depends_on = [google_project_service.apis]
}

# -----------------------------------------------------------------------------
# AlloyDB Cluster
# -----------------------------------------------------------------------------

# Even with IAM auth, AlloyDB requires an initial password for the default
# 'postgres' user. We generate one to satisfy the requirement, then ignore it.
resource "random_password" "alloydb_initial_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_alloydb_cluster" "main" {
  cluster_id = var.cluster_id
  location   = var.region

  network_config {
    network = google_compute_network.main.id
  }

  initial_user {
    password = random_password.alloydb_initial_password.result
  }
}

# -----------------------------------------------------------------------------
# AlloyDB Primary Instance
# -----------------------------------------------------------------------------

resource "google_alloydb_instance" "primary" {
  cluster       = google_alloydb_cluster.main.name
  instance_id   = var.primary_instance_id
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }

  # Public IP for connectivity from Cloud Shell and Colab Enterprise
  network_config {
    enable_public_ip = true
  }

  database_flags = {
    "alloydb.iam_authentication"                   = "on"
    "google_ml_integration.enable_model_support"   = "on"
    "google_ml_integration.enable_ai_query_engine" = "on"
    "password.enforce_complexity"                  = "on"
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

# Grant AlloyDB's service agent access to Vertex AI (for generating embeddings)
resource "google_project_iam_member" "alloydb_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-alloydb.iam.gserviceaccount.com"

  depends_on = [google_alloydb_cluster.main]
}

# Register the student's email as an IAM database user (no password needed)
resource "google_alloydb_user" "iam_user" {
  cluster        = google_alloydb_cluster.main.id
  user_id        = var.user_email
  user_type      = "ALLOYDB_IAM_USER"
  database_roles = ["alloydbsuperuser"]

  depends_on = [google_alloydb_instance.primary]
}

# -----------------------------------------------------------------------------
# Audit Logging — Data Access Logs
# -----------------------------------------------------------------------------
# BigQuery enables Data Access audit logs by default, but AlloyDB does not.
# This configuration turns them on so that every query the AI agent executes
# against AlloyDB is captured in Cloud Logging — giving you a complete audit
# trail across both databases.

resource "google_project_iam_audit_config" "alloydb_data_access" {
  project = var.project_id
  service = "alloydb.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "project_id" {
  description = "The project ID"
  value       = var.project_id
}

output "region" {
  description = "The deployment region"
  value       = var.region
}

output "cluster_id" {
  description = "The AlloyDB cluster ID"
  value       = google_alloydb_cluster.main.cluster_id
}

output "primary_instance_ip" {
  description = "The primary instance public IP address"
  value       = google_alloydb_instance.primary.public_ip_address
}

output "user_email" {
  description = "Your email (granted IAM database access)"
  value       = var.user_email
}
