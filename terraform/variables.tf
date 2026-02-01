# =============================================================================
# Team USA Analytics — Terraform Variables
# =============================================================================

variable "project_id" {
  description = "The Google Cloud project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The Google Cloud region for all resources"
  type        = string
  default     = "us-central1"
}

variable "user_email" {
  description = "The lab user's email address (for IAM database authentication)"
  type        = string
}

variable "cluster_id" {
  description = "The AlloyDB cluster identifier"
  type        = string
  default     = "team-usa-cluster"
}

variable "primary_instance_id" {
  description = "The AlloyDB primary instance identifier"
  type        = string
  default     = "team-usa-primary"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "team-usa-network"
}
