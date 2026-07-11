# Multi-Region Kubernetes Infrastructure & GitOps Platform

Production-grade, highly-available, and fault-tolerant Kubernetes infrastructure deployed across multiple AWS regions using Infrastructure as Code (IaC) and GitOps practices. Every push to the repository automatically builds, pushes, and triggers a rolling update of the containerized FastAPI microservice across all geographic Kubernetes clusters simultaneously via GitHub Actions.

## Architecture

```
               GitHub Push (main)
                    │
                    ▼
          GitHub Actions CI/CD
         ┌──────────┴──────────┐
         ▼                     ▼
    AWS Region 1          AWS Region 2
   (eu-central-1)         (eu-west-3)
  Frankfurt EC2          Paris EC2
         │                     │
   [K3s Cluster]         [K3s Cluster]
         │                     │
   Deployment v1         Deployment v1
   (ReplicaSet: 2)       (ReplicaSet: 2)
         │                     │
   NodePort: 30000       NodePort: 30000
```

## Features

- **Multi-Region Kubernetes Orchestration** — Active-Active lightweight Kubernetes (K3s) clusters distributed across Frankfurt (eu-central-1) and Paris (eu-west-3) for high availability.
- **True GitOps & CI/CD Pipeline** — GitHub Actions automates the entire lifecycle: builds the Docker image, pushes it to Docker Hub, and safely manipulates remote clusters using kubectl.
- **Dynamic Environment Injection** — The pipeline utilizes runtime configuration manipulation (sed) to inject real-time regional context into Kubernetes manifests before deployment.
- **High-Availability ReplicaSet** — Enforces a minimum of 2 healthy running Pods per region with an automated NodePort Service exposure at port 30000.
- **Secure Token Encapsulation** — Implements strict security best practices by encoding sensitive kubeconfig files into stateless Base64 strings within GitHub Secrets, bypassing environment-specific format corruption.
- **Infrastructure as Code (IaC)** — 100% of the underlying cloud network, security groups, and compute resources are provisioned and managed via Terraform.

## Tech Stack

- **Kubernetes (K3s)** - Lightweight enterprise-grade K8s cluster orchestration
- **Docker & Docker Hub** - Containerization and image registry management
- **Terraform** - Declarative Infrastructure as Code (IaC)
- **GitHub Actions** - Continuous Integration / Continuous Deployment (CI/CD)
- **FastAPI (Python)** - High-performance backend microservice
- **AWS EC2 & VPC** - Multi-region isolated cloud networking and compute nodes

## Repository Structure

| File / Folder | Description |
|---------------|-------------|
| terraform/main.tf | IaC definition for multi-region VPCs, subnets, and EC2 nodes |
| k8s/deployment.yml | Kubernetes Deployment manifest declaring high-availability replicas and placeholder targets |
| k8s/service.yml | Kubernetes Service config exposing the microservice via NodePort 30000 |
| .github/workflows/deploy.yml | Advanced GitOps workflow featuring parallel regional deployment and automated TLS bypasses |
| src/ | Python FastAPI application source code and custom production Dockerfile |

## CI/CD Pipeline Lifecycle

On every `git push origin main`:

1. **Build Phase** — GitHub Actions builds a production-ready multi-stage Docker image and tags it both as `latest` and with the unique `GITHUB_SHA`.
2. **Registry Phase** — The image is pushed to Docker Hub.
3. **Hydration Phase** — The pipeline uses `sed` to replace target region placeholders dynamically inside the Kubernetes manifests.
4. **GitOps Deploy Phase** — The runner extracts the Base64-encoded kubeconfig, authenticates against the public AWS instance API, skips untrusted TLS validation, and executes a zero-downtime rolling update via `kubectl rollout restart`.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/IvanLuketic2002/multi-region-kubernetes.git
cd multi-region-kubernetes

# 2. Provision AWS infrastructure through IaC
cd terraform
terraform init
terraform apply -auto-approve

# 3. Trigger automated multi-region GitOps deployment
cd ..
git add .
git commit -m "feat: infrastructure scale-up"
git push origin main

# 4. Test live multi-region availability
curl http://<FRANKFURT_PUBLIC_IP>:30000/
curl http://<PARIS_PUBLIC_IP>:30000/
```

## GitHub Secrets Required

| Secret Name | Description |
|-------------|-------------|
| DOCKERHUB_USERNAME | Docker Hub registry profile identity |
| DOCKERHUB_TOKEN | Secure access token for pushing images |
| KUBECONFIG_FRANKFURT | Base64 encoded string of the Frankfurt `/etc/rancher/k3s/k3s.yaml` file (with replaced public IP) |
| KUBECONFIG_PARIZ | Base64 encoded string of the Paris `/etc/rancher/k3s/k3s.yaml` file (with replaced public IP) |

## Cost Optimization & Cleanup

To destroy all provisioned AWS cloud resources instantly and avoid unwanted billing:

```bash
cd terraform
terraform destroy -auto-approve
```
