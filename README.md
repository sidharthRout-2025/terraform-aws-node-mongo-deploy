# 🚀 Terraform AWS Node.js + MongoDB Deployment

## 🌍 Overview

This project deploys a **containerized Node.js REST API** connected to a **self-managed MongoDB** database running on an **EC2 instance**, orchestrated via **AWS ECS (EC2 launch type)**.

The entire infrastructure is **automated with Terraform**, following a **modular design** and using **S3 + DynamoDB** for state storage and locking.

---

## 🗂️ Repository Structure

| Folder / File                | Description                                                     |
| ---------------------------- | --------------------------------------------------------------- |
| `app/`                       | Node.js Express application with MongoDB connection             |
| `terraform/`                 | Terraform root configuration and reusable modules               |
| `terraform/modules/network/` | Creates VPC, subnets, and Internet Gateway                      |
| `terraform/modules/ecr/`     | Creates AWS ECR repository to store Docker image                |
| `terraform/modules/mongo/`   | Launches EC2 instance running MongoDB                           |
| `terraform/modules/ecs_ec2/` | ECS Cluster, EC2 Auto Scaling Group, and ECS Service            |
| `terraform/modules/alb/`     | Application Load Balancer (ALB) and Target Group                |
| `ecs-ec2-vs-fargate.md`      | Comparison between ECS EC2 and Fargate modes                    |
| `README.md`                  | This guide — full setup, build, deploy, and access instructions |

---

## ⚙️ Prerequisites

Before you begin, ensure the following are ready:

* **AWS CLI** configured → `aws configure`
* **Terraform** v1.2+ installed
* **Docker** installed and running
* **IAM permissions** to create ECS, EC2, ALB, S3, DynamoDB, and related resources
* **Key pair name** in AWS (for SSH access to MongoDB EC2)

---

## 🪣 Step 1: Setup Terraform Backend

Terraform stores its deployment state remotely to prevent conflicts.

### 💡 What It Does

Creates a backend for Terraform state management:

* **S3 Bucket** — stores Terraform state files
* **DynamoDB Table** — locks state to prevent concurrent modification

### 🦾 Commands

```bash
aws s3api create-bucket \
  --bucket my-terraform-state-bucket-unique \
  --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1

aws dynamodb create-table \
  --table-name tfstate-lock-table-unique \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### ⚙️ Then update `terraform/variables.tf`

```hcl
tfstate_bucket     = "my-terraform-state-bucket-unique"
tfstate_lock_table = "tfstate-lock-table-unique"
```

---

# 🚀 Deployment Steps — Build, Deploy & Access Application

---

## 🧱 Step 2: Build & Push Docker Image

The **Node.js** app will be containerized and pushed to **Amazon ECR** for use by **ECS**.

### 💡 What It Does

* Builds a Docker image locally
* Tags it for your **AWS ECR** repository
* Pushes it so ECS tasks can pull it at runtime

### 🦾 Commands

```bash
cd app
docker build -t devops-tech-test-app:latest .

AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-tech-test-app"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPO

# Tag and push image
docker tag devops-tech-test-app:latest $REPO:latest
docker push $REPO:latest
```

✅ **Result:**
Your image is now stored in **ECR** and ready to be used by **ECS**.

---

## 🏗️ Step 3: Deploy Infrastructure with Terraform

Terraform automates the deployment of all required **AWS components** to host your **Node.js + MongoDB** application on **ECS (EC2 launch type)**.

### 💡 What It Creates

The Terraform configuration provisions:

* **VPC, Subnets, and Internet Gateway** — builds public/private networking layers
* **Security Groups** — allow communication between ALB, ECS, and MongoDB EC2 instance
* **Application Load Balancer (ALB)** — routes traffic to ECS containers on port 80
* **ECS Cluster (EC2 Launch Type)** — runs Docker containers via EC2 Auto Scaling Group
* **EC2 Instance running MongoDB** — self-managed MongoDB database
* **ECS Task Definition and Service** — defines and deploys the Node.js container

### 🦾 Commands

```bash
cd terraform

# Initialize Terraform (downloads providers and configures backend)
terraform init

# Create and review execution plan
terraform plan -out plan.tf

# Apply to deploy infrastructure
terraform apply "plan.tf"
```

### 📤 Outputs after Apply

```text
alb_dns_name     = app-alb-1234567890.us-east-1.elb.amazonaws.com
ecs_cluster_name = devops-tech-test-ecs-cluster
ecs_service_name = devops-tech-test-service
```

✅ **Result:**
Infrastructure deployed successfully. The ALB DNS name provides access to your application.

---

### 🌐 Step 4: Access the Application

Once Terraform deployment is complete, you can access the running **Node.js + MongoDB** app via the **ALB DNS name** output.

### 💡 What It Does

Routes HTTP traffic through:
**Internet → ALB → ECS (EC2) → Node.js Container → MongoDB on EC2**

This ensures secure and functional communication between services.

### 🦾 Test the Application

```bash
curl http://<ALB_DNS>/
```

### ✅ Expected Output

```json
{
  "status": "ok",
  "message": "Node.js + MongoDB on ECS (EC2)"
}
```

---

### 🧪 Add and Retrieve Data

You can now interact with the API to add and fetch data.

```bash
# Add a new item to MongoDB
curl -X POST -H "Content-Type: application/json" \
  -d '{"name":"FromTerraform"}' http://<ALB_DNS>/items

# Retrieve items from MongoDB
curl http://<ALB_DNS>/items
```

✅ **MongoDB stores and returns your data successfully.**

---

### 🧹 Step 5: Verify MongoDB (Optional)

If you want to confirm MongoDB status directly, SSH into the EC2 instance.

```bash
ssh -i my-key.pem ec2-user@<Mongo_EC2_Public_IP>
sudo systemctl status mongodb
```

If successful, you should see:

```
● mongodb.service - An object/document-oriented database
     Loaded: loaded (/lib/systemd/system/mongodb.service; enabled)
     Active: active (running)
```

✅ **MongoDB is running and integrated successfully.**

---

## 🪯 Cleanup Resources

When finished, destroy resources to prevent extra AWS costs:

```bash
cd terraform
terraform destroy -auto-approve
```

---

