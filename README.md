# Redis on GCE with Terraform & Google Cloud Monitoring

This repository contains a production-ready Terraform setup to deploy a lightweight, cost-effective Redis cache on Google Compute Engine (**GCE**) in the `us-central1` region (**GCP Free Tier eligible**).

The solution features automatic key eviction (auto-cleanup), Google Cloud Ops Agent integration, and an automated Google Cloud Monitoring Alert Policy that sends email notifications if memory usage exceeds **80%**.

---

## 🚀 Key Features

* **GCP Free Tier Eligible:** Deploys an `e2-micro` instance with a 15GB `pd-standard` boot disk in `us-central1` ($0.00/month compute cost on GCP Free Tier).
* **Automated Memory Cleanup Best Practices:**
  * Capped max memory (`maxmemory 550mb`).
  * `allkeys-lru` eviction policy (automatically removes the Least Recently Used keys when memory limit is reached).
  * Password protection (`requirepass`).
  * Listens on all internal interfaces (`0.0.0.0`) with `protected-mode yes`.
* **Google Cloud Monitoring & Telemetry:**
  * Automatically installs and configures the **Google Cloud Ops Agent** on the VM.
  * Ingests system RAM metrics and Redis server metrics into Cloud Monitoring.
  * Configures an **Email Alert Policy** that triggers when GCE memory utilization exceeds **80%** for 5 minutes.
* **Security & Networking:**
  * Attaches a dedicated Service Account with minimal IAM roles (`roles/monitoring.metricWriter`, `roles/logging.logWriter`).
  * Firewall rule allowing ingress on TCP port `6379` strictly from internal VPC networks (`10.0.0.0/8`, etc.).

---

## 🛠️ Prerequisites

Before deploying, ensure you have the following installed and configured:

1. **Terraform** >= 1.5.0 installed ([Download Terraform](https://developer.hashicorp.com/terraform/downloads)).
2. **Google Cloud SDK (`gcloud`)** installed and authenticated:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. **Required GCP APIs Enabled** on your GCP project:
   ```bash
   gcloud services enable compute.googleapis.com monitoring.googleapis.com logging.googleapis.com --project=YOUR_PROJECT_ID
   ```

---

## 📋 Deployment Instructions

### Step 1: Clone & Navigate to the Directory
```bash
cd redis-gce-terraform
```

### Step 2: Configure Terraform Variables
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your text editor of choice and fill in your details:
```hcl
project_id          = "your-actual-gcp-project-id"
region              = "us-central1"
zone                = "us-central1-a"
instance_name       = "redis-instance"
machine_type        = "e2-micro"
disk_size_gb        = 15
network_name        = "default"
redis_password      = "YourStrongPasswordHere123!"
redis_maxmemory_mb  = 550
alert_email_address = "your-email@domain.com"
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Review Deployment Plan
```bash
terraform plan
```

### Step 5: Apply Infrastructure
```bash
terraform apply
```
When prompted, type `yes` to confirm the resource creation.

---

## 🔗 Connecting Cloud Run to Redis

To connect your Cloud Run service (located in `us-central1`) to this Redis instance:

1. Obtain the **Internal IP** of the Redis VM from the Terraform output:
   ```bash
   terraform output redis_internal_ip
   ```
2. In your Cloud Run service configuration:
   * Enable **Direct VPC Egress** pointing to the `default` VPC subnet in `us-central1`.
   * Set your application environment variable for Redis connection string:
     ```
     REDIS_URL=redis://:<redis_password>@<redis_internal_ip>:6379
     ```

---

## 🔍 Verification & Testing

### 1. Verify Redis Status on GCE VM
SSH into the VM via `gcloud`:
```bash
gcloud compute ssh redis-instance --zone=us-central1-a
```

Inside the VM, inspect Redis memory configuration and eviction policy:
```bash
redis-cli -a "YourStrongPasswordHere123!" info memory
```
Look for:
* `maxmemory_human: 550.00M`
* `maxmemory_policy: allkeys-lru`

### 2. Verify Google Cloud Ops Agent Status
Check that the Ops Agent is active and transmitting metrics:
```bash
sudo systemctl status google-cloud-ops-agent
```

### 3. Verify Alert Policy in GCP Console
Navigate to **Google Cloud Console > Monitoring > Alerting**. You will see the policy named **`Redis GCE Memory Usage Exceeds 80%`** linked to your notification channel.

---

## 🧹 Teardown / Cleanup

To destroy all created GCP resources (VM, Firewall, Service Account, and Alert Policy):

```bash
terraform destroy
```
