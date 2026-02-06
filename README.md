# Scaling Modern Applications with Infrastructure as Code and CI/CD on Google Cloud

> Demo repository for the GDG Ilorin talk — February 7, 2026

A complete, working example of how to provision infrastructure, containerize an app, and set up automated deployments on Google Kubernetes Engine. Everything is version-controlled. Nothing is manual.

## Architecture

```
You (git push)
  │
  ▼
GitHub Actions ─────────────────────────────────────────────────
  │  1. Build Docker image from app/
  │  2. Tag with commit hash (unique per deploy)
  │  3. Push image to Artifact Registry
  │  4. Replace "latest" tag in K8s manifest with commit hash
  │  5. kubectl apply → rolling update on GKE
  │
  ▼
Google Cloud (eu-west1) ────────────────────────────────────────

  ┌──────────────────┐      ┌─────────────────────────────┐
  │ Artifact Registry│      │       GKE Cluster            │
  │                  │      │                              │
  │  app:a3f9b2c     │─────▶│   ┌─────┐ ┌─────┐ ┌─────┐  │
  │  app:d7e4f1a     │      │   │Pod 1│ │Pod 2│ │Pod 3│  │
  │  app:...         │      │   └──┬──┘ └──┬──┘ └──┬──┘  │
  └──────────────────┘      │      └───────┼───────┘     │
                            │              │              │
                            │       LoadBalancer          │
                            │        (Public IP)          │
                            └──────────────┼──────────────┘
                                           │
                                        Users
────────────────────────────────────────────────────────────────

Terraform (one-time)
  Provisions: GKE Cluster + Artifact Registry + Node Pool
  Defined in: terraform/main.tf
  Config in:  terraform/variables.tf
```

### How It Works

1. **Terraform** provisions the GKE cluster and Artifact Registry (one-time setup)
2. **You** push code to the `main` branch
3. **GitHub Actions** builds a Docker image, tags it with the commit hash, pushes to Artifact Registry
4. **GitHub Actions** updates the K8s deployment manifest with the new tag, applies it to GKE
5. **GKE** performs a rolling update — new pods come up, old pods go down, zero downtime
6. **Users** see the updated app at the LoadBalancer's public IP
7. **Kubernetes** self-heals — if a pod crashes, it's automatically replaced

## The Stack

| Tool | Role | Files |
|------|------|-------|
| **Terraform** | Infrastructure provisioning | `terraform/main.tf`, `terraform/variables.tf` |
| **Docker** | App packaging | `app/Dockerfile` |
| **GitHub Actions** | CI/CD pipeline | `.github/workflows/deploy.yaml` |
| **Kubernetes (GKE)** | Container orchestration | `K8s/deployment.yaml`, `K8s/service.yaml` |

## Project Structure

```
gdg-ilorin-cloud/
├── app/
│   ├── index.html          # The web application
│   └── Dockerfile          # Packages the app with Nginx
├── terraform/
│   ├── main.tf             # Infrastructure definition (cluster, registry, nodes)
│   └── variables.tf        # Configurable values (project ID, region, etc.)
├── K8s/
│   ├── deployment.yaml     # How Kubernetes runs the app (3 replicas)
│   └── service.yaml        # How Kubernetes exposes the app (LoadBalancer)
└── .github/
    └── workflows/
        └── deploy.yaml     # CI/CD pipeline (build → push → deploy)
```

## Setup Guide

### Prerequisites

- A Google Cloud account with billing enabled
- A GitHub account
- Google Cloud Shell (recommended) or local machine with `gcloud`, `terraform`, `kubectl`, and `docker` installed

### Step 1: Clone and Configure

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/gdg-ilorin-cloud.git
cd gdg-ilorin-cloud

# Set your GCP project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com artifactregistry.googleapis.com
```

### Step 2: Create the GitHub Secret (GCP_SA_KEY)

The CI/CD pipeline needs a service account key to authenticate to Google Cloud. Here's how to create one:

```bash
# Set your project ID
PROJECT_ID=$(gcloud config get-value project)

# Create a service account for GitHub Actions
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub Actions Deployer"

# Grant it permission to push Docker images
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Grant it permission to deploy to GKE
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Generate the JSON key
gcloud iam service-accounts keys create key.json \
  --iam-account=github-deployer@$PROJECT_ID.iam.gserviceaccount.com

# Display the key — copy the ENTIRE output
cat key.json

# Go to GitHub → your repo → Settings → Secrets and Variables → Actions
# Create a new secret named: GCP_SA_KEY
# Paste the entire JSON content as the value

# DELETE the local key file — never leave credentials lying around
rm key.json
```

### Step 3: Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
# Type 'yes' when prompted. This takes ~10 minutes.
```

This creates:
- An Artifact Registry repository for Docker images
- A GKE cluster with 2 nodes (e2-medium)

### Step 4: Deploy the App for the First Time

```bash
# Connect kubectl to the cluster
gcloud container clusters get-credentials ilorin-city-cluster --zone eu-west1-b

# Configure Docker for Artifact Registry
gcloud auth configure-docker eu-west1-docker.pkg.dev

# Build and push the initial image
cd ../app
docker build -t eu-west1-docker.pkg.dev/YOUR_PROJECT_ID/ilorin-app-repo/app:v1 .
docker push eu-west1-docker.pkg.dev/YOUR_PROJECT_ID/ilorin-app-repo/app:v1

# Temporarily set the image tag to v1 for initial deploy
# In K8s/deployment.yaml, change ":latest" to ":v1"
cd ..
kubectl apply -f K8s/

# Wait for the LoadBalancer to get a public IP
kubectl get service ilorin-watch-service --watch
# Once EXTERNAL-IP appears (not <pending>), open it in your browser

# IMPORTANT: Change the image tag back to ":latest" in K8s/deployment.yaml
# and push to GitHub — the pipeline needs "latest" so sed can replace it
```

### Step 5: Deploy Changes (The CI/CD Way)

From now on, you never deploy manually:

```bash
# Edit app/index.html (change color, text, etc.)
git add .
git commit -m "feat: updated the app"
git push origin main

# Go to GitHub → Actions tab → watch the pipeline run
# When it finishes, refresh your app — changes are live
```

## Forking This Repo

If you want to use this for your own project, update these values:

| File | What to change |
|------|---------------|
| `terraform/variables.tf` | Set your own defaults, or pass `-var="project_id=..."` at apply time |
| `K8s/deployment.yaml` | Update the `image` path with your project ID and region |
| `.github/workflows/deploy.yaml` | Update the `env` block at the top (project ID, region, zone) |
| GitHub Secrets | Create `GCP_SA_KEY` with your own service account key |

## Testing Self-Healing

```bash
# Connect to your cluster
gcloud container clusters get-credentials ilorin-city-cluster --zone eu-west1-b

# List running pods
kubectl get pods

# Delete a pod (pick any one)
kubectl delete pod <POD_NAME>

# Watch Kubernetes replace it automatically
kubectl get pods --watch
```

The Deployment spec says `replicas: 3`. Kubernetes continuously reconciles actual state with desired state. When a pod dies, a replacement is created within seconds.

## Tear Down

When you're done, clean up to avoid charges:

```bash
# Delete K8s resources first
kubectl delete -f K8s/

# Destroy Terraform-managed infrastructure
cd terraform
terraform destroy -var="project_id=YOUR_PROJECT_ID"
# Type 'yes' when prompted
```

---

Built for the GDG Ilorin community by Amina Lawal.
