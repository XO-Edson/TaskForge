# TaskForge — DevOps Portfolio Application

A deliberately simple task-management application designed to become the application layer of an end-to-end DevOps portfolio project.

## Local stack

- React + Vite
- Node.js + Express
- PostgreSQL
- Docker Compose

## Run locally

```bash
docker compose up --build
```

Then open:

- Frontend: http://localhost:5173
- API health: http://localhost:4000/api/health

## What comes next

The application is intentionally ready to evolve into:

GitHub → Jenkins → Docker → ECR → EKS → RDS PostgreSQL → Prometheus → Grafana

Terraform will provision the AWS infrastructure, and Kubernetes manifests will replace the local Compose deployment for the cloud environment.
