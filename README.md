# Intent Classifier — AWS Production Deployment
Production deployment of an NLP Intent Classification model on AWS, using a fully automated infrastructure with Auto Scaling and Load Balancing.

---

## Architecture
```
User Request
     │
     ▼
Application Load Balancer (ALB)
  - Internet-facing
  - HTTP:80
  - DNS: intent-classifier-alb.us-east-1.elb.amazonaws.com
     │
     ▼
Target Group (mlops-target-group)
  - Health check: GET /
  - Port: 80
     │
     ▼
Auto Scaling Group (1–3 EC2 instances)
  - Min: 1 | Desired: 1 | Max: 3
  - Launch Template (Ubuntu 20.04, t3.micro)
  - Automatically registers new instances to Target Group
     │
     ▼
EC2 Instance (Ubuntu 20.04)
  ├── Nginx (port 80) — reverse proxy
  └── Gunicorn (port 6000) — WSGI server
        └── Intent Classifier Model (Python/Flask)
```
## Screenshots

### ALB Active
![ALB Active](screenshots/ALB.png)

### Target Group Healthy
![Target Group Healthy](screenshots/target-group-healthy.png)

### Auto Scaling Group
![ASG](screenshots/ASG.png)
---

## Tech Stack
| Layer | Technology |
|---|---|
| Cloud Provider | AWS |
| Compute | EC2 (t3.micro, Ubuntu 20.04) |
| Scaling | Auto Scaling Group (ASG) |
| Load Balancing | Application Load Balancer (ALB) |
| Networking | VPC, Public Subnets (multi-AZ), Internet Gateway |
| Security | Security Groups (HTTP + SSH) |
| Web Server | Nginx (reverse proxy) |
| App Server | Gunicorn (WSGI) |
| ML Framework | Python, scikit-learn |
| IaC | AWS CLI |
| Provisioning | EC2 User Data (shell script) |

---

## Project Structure
```
intent-classifier-aws-deploy/
├── README.md
├── infrastructure/
│   ├── userdata.sh        # EC2 bootstrap script (installs app on launch)
│   └── setup.sh           # Full AWS CLI infrastructure setup
└── docs/
    └── deploy-guide.md    # Step-by-step deployment guide
```

---

## What the Infrastructure Does

### 1. VPC & Networking
A dedicated VPC with two public subnets across different Availability Zones, connected to an Internet Gateway with routing configured for public access.

### 2. Security Group
Allows inbound HTTP (port 80) for application traffic and SSH (port 22) for administration.

### 3. EC2 Launch Template
Defines the instance configuration: Ubuntu 20.04 AMI, t3.micro instance type, security group, and the `userdata.sh` bootstrap script that automatically:
- Installs system dependencies (git, python3, nginx)
- Clones the model repository from GitHub
- Sets up a Python virtual environment
- Installs Python dependencies
- Trains the ML model
- Configures Gunicorn as a systemd service
- Configures Nginx as a reverse proxy

### 4. Auto Scaling Group
Ensures high availability by maintaining the desired number of running instances. Automatically replaces unhealthy instances and scales between 1 and 3 instances based on demand.

### 5. Application Load Balancer
Single entry point for all traffic. Distributes requests across healthy EC2 instances and performs health checks to route traffic only to available targets.

---

## How to Deploy

### Prerequisites
- AWS CLI configured (`aws configure`)
- An existing EC2 Key Pair

### Quick Deploy
```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/intent-classifier-aws-deploy
cd intent-classifier-aws-deploy

# Edit variables in setup.sh
vim infrastructure/setup.sh

# Run the full infrastructure setup
bash infrastructure/setup.sh
```

See [docs/deploy-guide.md](docs/deploy-guide.md) for the full step-by-step guide.

---

## API Usage
Once the ALB is active and the target group shows healthy instances:

```bash
# Classify an intent
curl -X POST http://<ALB-DNS-NAME> \
  -H "Content-Type: application/json" \
  -d '{"text": "book a flight to New York"}'
```

---

## Key AWS CLI Commands Used
```bash
# Check instance health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name mlops-autoscaling \
  --region us-east-1 \
  --query "AutoScalingGroups[0].Instances"

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region us-east-1

# Check ALB DNS
aws elbv2 describe-load-balancers \
  --names intent-classifier-alb \
  --region us-east-1 \
  --query "LoadBalancers[0].DNSName"
```

---

## Author
Anderson Cruz
Senior Data Scientist | MLOps
[LinkedIn](https://linkedin.com/in/anderjcruz) • [GitHub](https://github.com/AnderCruz)
