# Scaling Modern Applications with Infrastructure as Code and CI CD on Google Cloud 


## Demo for GDG Ilorin Tech Event

> "Stop building Villages (Manual). Start building Cities (Automated)."

This is the official demo repository for my session at **Scaling Modern Applications**. We are using Terraform to provision a Google Kubernetes Engine (GKE) cluster and GitHub Actions to deploy a self-healing web application.

## The Stack
* **Infrastructure:** Terraform
* **Containerization:** Docker
* **Orchestration:** Kubernetes (GKE)
* **CI/CD:** GitHub Actions

## How to Run This (The "City" Way)

### 1. Prerequisites
You need a Google Cloud Project and the `gcloud` CLI installed.

### 2. The Blueprint (Terraform)
Navigate to the terraform folder and order your infrastructure:
```bash
cd terraform
terraform init
terraform apply
```

### 3. The Deployment (CI/CD)
You don't deploy manually!

1. Go to app/index.html and change the background color.
2. Commit and Push:
```bash
git add .
git commit -m "New feature: Green Background"
git push origin main
```
3. Go to the Actions tab in this repo and watch the magic happen.



### **4. The "Glue" (Connecting Manifests to Pipeline)**

**Crucial Step**
In your GitHub Actions YAML (`.github/workflows/deploy.yaml`), you need a step that updates the `deployment.yaml` file with the new image tag before applying it.

Add this step to your pipeline right before the `kubectl apply` command:

```yaml
    - name: Deploy to GKE
      run: |
        # 1. Get the GKE Credentials
        gcloud container clusters get-credentials ilorin-city-cluster --zone us-central1-a
        
        # 2. Update the image tag in the deployment file dynamically
        # This replaces "latest" with the specific Git Commit Hash
        sed -i "s/latest/$GITHUB_SHA/g" k8s/deployment.yaml
        
        # 3. Apply the changes to the City
        kubectl apply -f k8s/
```

#### The "Chaos" Test
Want to test self-healing?

1. Connect to your cluster: `gcloud container clusters get-credentials ...`
2. Delete a pod: `kubectl delete pod [POD_NAME]`
3. Watch it come back to life: `kubectl get pods -w`

Built with ❤️ for the GDG Ilorin Tech Community by Amina Lawal.
