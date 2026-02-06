provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Artifact Registry — stores our Docker images
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "ilorin-app-repo"
  format        = "DOCKER"
}

# 2. GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Remove the default node pool — we define our own below
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

# 3. Node Pool — the VMs that Kubernetes runs on
resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  cluster    = google_container_cluster.primary.id
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
