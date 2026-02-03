provider "google" {
  project = "aminas-project"
  region  = "us-central1"
}

# 1. The Warehouse (Artifact Registry)
resource "google_artifact_registry_repository" "repo" {
  location      = "us-central1"
  repository_id = "ilorin-app-repo"
  format        = "DOCKER"
}

# 2. The City (GKE Cluster)
resource "google_container_cluster" "primary" {
  name     = "ilorin-city-cluster"
  location = "us-central1-a"
  
  # We start small - 1 node to save money (The "Village" size)
  initial_node_count = 1 

  # But we enable the magic...
  deletion_protection = false
}

# 3. The Workers (Node Pool)
resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  cluster    = google_container_cluster.primary.id
  node_count = 2 # Scaling up to 2 workers

  node_config {
    machine_type = "e2-medium" # Affordable standard machine
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}