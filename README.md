# PrepAI — AI Mock Interviewer

A full-stack AI-powered mock interview platform where users practice role-specific technical interviews, receive instant AI feedback, and track their performance over time. Built end-to-end — from code to cloud — as a complete DevOps learning project covering containerization, Kubernetes orchestration, cloud provisioning, and CI/CD.

---

## What This Project Covers

PrepAI is not just an application — it is a hands-on DevOps project that walks through the entire lifecycle of deploying a real-world full-stack application to the cloud.

| Area | What Was Done |
|------|---------------|
| **Application** | Full-stack Next.js + FastAPI + PostgreSQL + OpenAI |
| **Containerization** | Multi-service Docker setup with Dockerfiles for frontend and backend |
| **Orchestration** | Kubernetes (K8s) manifests for all services, deployments, and services |
| **Cloud Infrastructure** | AWS EC2 instance provisioned and configured as a K8s node |
| **Infrastructure as Code** | Terraform used to provision AWS resources |
| **Container Registry** | Docker images pushed to Docker Hub and pulled by K8s |
| **Environment Config** | Next.js `NEXT_PUBLIC_*` build-arg injection pattern for containerized builds |
| **Networking** | NodePort services exposing frontend and backend over public EC2 IP |

---

## Application Features

- **AI-Powered Sessions:** Dynamically generates technical, behavioral, and practical questions based on the user's requested job role and difficulty (Easy / Medium / Hard).
- **Instant Feedback:** Evaluates answers in real-time with a score out of 10 and constructive feedback on missing elements.
- **Progress Tracking:** Dashboard with full historical session tracking and automated performance ratings (Great / Okay / Needs Work).
- **Premium UI/UX:** Built with Tailwind CSS and Framer Motion — deep navy aesthetic, smooth micro-interactions, responsive gradients, and authenticated floating states.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Next.js 14 (App Router), React, Tailwind CSS, Framer Motion, Lucide React |
| **Backend** | FastAPI (Python 3.11), SQLAlchemy |
| **Database** | PostgreSQL 15 |
| **AI Integration** | OpenAI GPT-4o API |
| **Auth** | Custom JWT + `bcrypt` implementation |
| **Containerization** | Docker, Docker Compose |
| **Orchestration** | Kubernetes (kubectl, manifests) |
| **Cloud** | AWS EC2 (Ubuntu) |
| **IaC** | Terraform |
| **Registry** | Docker Hub |

---

## Project Structure

```
PrepAI/
│
├── frontend/                         ← Next.js 14 Application
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.js               ← Landing page
│   │   │   ├── login/page.js         ← Split-screen Login
│   │   │   ├── signup/page.js        ← Split-screen Signup
│   │   │   ├── dashboard/page.js     ← Protected user portal
│   │   │   ├── interview/[id]/page.js← Real-time interview screen
│   │   │   └── results/[id]/page.js  ← Post-interview score breakdown
│   │   ├── components/
│   │   │   └── Navbar.js             ← Global navigation
│   │   └── lib/
│   │       └── api.js                ← Axios bindings + interceptors
│   ├── Dockerfile                    ← Multi-stage Next.js Docker build
│   └── .env.local                    ← Local env (not committed)
│
├── backend/                          ← FastAPI Application
│   ├── main.py                       ← App entry point
│   ├── database.py                   ← PostgreSQL engine
│   ├── models.py                     ← SQLAlchemy ORM models
│   ├── schemas.py                    ← Pydantic schemas
│   ├── auth.py                       ← JWT + bcrypt
│   ├── openai_service.py             ← GPT-4o prompts & structured output
│   ├── routers/
│   │   ├── auth_router.py
│   │   ├── sessions_router.py
│   │   └── answers_router.py
│   └── Dockerfile                    ← FastAPI Docker build
│
├── k8s/                              ← Kubernetes Manifests
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── postgres-pvc.yaml
│
└── terraform/                        ← Infrastructure as Code
    ├── main.tf                       ← AWS provider + EC2 instance
    ├── variables.tf
    └── outputs.tf
```

---

## DevOps Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      AWS EC2 (Ubuntu)                    │
│                                                          │
│   ┌─────────────────────────────────────────────────┐   │
│   │              Kubernetes Cluster                 │   │
│   │                                                 │   │
│   │   ┌─────────────┐   ┌─────────────┐            │   │
│   │   │  Frontend   │   │   Backend   │            │   │
│   │   │  (Next.js)  │──▶│  (FastAPI)  │            │   │
│   │   │  NodePort   │   │  NodePort   │            │   │
│   │   │  :30000     │   │  :30001     │            │   │
│   │   └─────────────┘   └──────┬──────┘            │   │
│   │                            │                   │   │
│   │                    ┌───────▼──────┐            │   │
│   │                    │  PostgreSQL  │            │   │
│   │                    │  (ClusterIP) │            │   │
│   │                    │  + PVC       │            │   │
│   │                    └──────────────┘            │   │
│   └─────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
         ▲                       ▲
  Browser: EC2_IP:30000    API: EC2_IP:30001
```

---

## Infrastructure Setup (Terraform)

AWS resources were provisioned using Terraform — no manual clicking in the console.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This provisions an EC2 instance with the correct security group rules to allow traffic on ports `30000` (frontend) and `30001` (backend).

> **Note:** Terraform state files (`terraform.tfstate`) and `.terraform/` are gitignored. Never commit state files — they contain sensitive infrastructure details.

---

## Docker Setup

### Building Images

Both the frontend and backend have their own `Dockerfile`.

**Important — Next.js `NEXT_PUBLIC_*` variables are baked in at build time.** When building the frontend Docker image, the API URL must be passed as a build argument:

```bash
# Build frontend with the production API URL injected at build time
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=http://<EC2_PUBLIC_IP>:30001 \
  -t <dockerhub-username>/prepai-frontend:latest \
  ./frontend

# Build backend
docker build -t <dockerhub-username>/prepai-backend:latest ./backend
```

### Pushing to Docker Hub

```bash
docker push <dockerhub-username>/prepai-frontend:latest
docker push <dockerhub-username>/prepai-backend:latest
```

### Why `.env.local` Is Not Enough for Docker

Next.js embeds `NEXT_PUBLIC_*` variables during `next build`. If the Dockerfile does not explicitly pass the variable via `ARG`/`ENV` before the build step, the variable is ignored — even if `.env.local` exists on your host machine. The correct pattern in the Dockerfile:

```dockerfile
# In frontend/Dockerfile, before RUN npm run build:
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
```

---

## Kubernetes Deployment

### Prerequisites on EC2

- Kubernetes installed (kubeadm / k3s / minikube)
- `kubectl` configured
- Docker Hub images already pushed

### Apply All Manifests

```bash
# From the project root on EC2
kubectl apply -f k8s/
```

This creates:
- PostgreSQL `Deployment` + `ClusterIP` Service + `PersistentVolumeClaim`
- Backend `Deployment` + `NodePort` Service (port `30001`)
- Frontend `Deployment` + `NodePort` Service (port `30000`)

### Backend Environment (Secrets / ConfigMap)

The backend deployment reads database credentials and API keys from Kubernetes environment variables. Set these either via a `Secret` manifest or by directly including them in the deployment YAML:

```yaml
env:
  - name: DATABASE_URL
    value: "postgresql://postgres:password@postgres-service:5432/mockinterview"
  - name: OPENAI_API_KEY
    value: "sk-..."
  - name: SECRET_KEY
    value: "your-jwt-secret"
```

> For production, use Kubernetes `Secrets` instead of plaintext values.

### Verify Deployment

```bash
kubectl get pods
kubectl get services
kubectl logs <pod-name>
```

### Access the Application

| Service | URL |
|---------|-----|
| Frontend | `http://<EC2_PUBLIC_IP>:30000` |
| Backend API Docs | `http://<EC2_PUBLIC_IP>:30001/docs` |

> Make sure the EC2 Security Group inbound rules allow TCP traffic on ports `30000` and `30001` from `0.0.0.0/0`.

---

## Local Development Setup

To run this application locally without Docker or Kubernetes, you will need Node.js, Python 3.11+, and a running PostgreSQL instance.

### 1. Environment Variables

**Backend (`backend/.env`):**
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/mockinterview
OPENAI_API_KEY=sk-your-openai-api-key-here
SECRET_KEY=your-secure-jwt-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

**Frontend (`frontend/.env.local`):**
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 2. Start the Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### 3. Start the Frontend

```bash
cd frontend
npm install
npm run dev
```

### 4. Visit the Application
- App: `http://localhost:3000`
- API Docs: `http://localhost:8000/docs`

---

## Key Lessons Learned

- **Next.js build-time env injection:** `NEXT_PUBLIC_*` variables must be passed as Docker `--build-arg`, not just mounted at runtime. A running container cannot retroactively change values baked into the JavaScript bundle.
- **Kubernetes service DNS:** Pods communicate with each other using service names as hostnames (e.g., `postgres-service:5432`), not `localhost`.
- **NodePort vs ClusterIP:** External traffic (browser → app) needs `NodePort`. Internal traffic (backend → database) uses `ClusterIP`.
- **Terraform state management:** Never commit `.tfstate` files. Use remote state (S3 backend) in team environments.
- **EC2 Security Groups are the firewall:** Kubernetes opens the port, but AWS Security Groups must also allow that port — both must be configured.
- **`.env` files are gitignored by design:** Secrets never go into source control. Use Kubernetes Secrets or environment injection at deploy time.
