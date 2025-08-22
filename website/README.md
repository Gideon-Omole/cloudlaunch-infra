# 🌩️ CloudLaunch – AWS Deployment (AltSchool Semester 3 Assessment)

This project implements the **CloudLaunch** platform using **AWS core services** and **Terraform**.  

It demonstrates AWS fundamentals such as **S3 (static hosting + private storage)**, **IAM (least-privilege access)**, and **VPC design (subnets, route tables, and security groups)**.  

> **Note**: All resources are deployed in **AWS Free Tier eligible services only**. No EC2, NAT Gateways, or RDS were provisioned.

---

## 📂 Project Structure

cloudlaunch-assessment/
│── main.tf # Terraform providers + backend setup
│── variables.tf # Input variables (region, CIDRs, etc.)
│── outputs.tf # Key resource outputs (S3 URLs, VPC ID, etc.)
│── s3.tf # S3 buckets + CloudFront (bonus)
│── iam.tf # IAM user + policies
│── vpc.tf # VPC, subnets, route tables, security groups
│── policies/
│ ├── cloudlaunch-user-policy.json
│ └── cloudlaunch-vpc-readonly-policy.json
│── website/
│ └── index.html # Basic CloudLaunch landing page
│── README.md # Project documentation



---

## 📝 Task 1: Static Website Hosting + IAM User

### ✅ S3 Buckets
1. **cloudlaunch-site-bucket**
   - Hosts a **basic static website** (`index.html`).
   - Public read-only access enabled.
   - Bonus: Served via **CloudFront** for HTTPS + caching.

2. **cloudlaunch-private-bucket**
   - Private bucket for storing internal files.
   - Accessible only by the `cloudlaunch-user` IAM user.
   - Permissions: `GetObject` + `PutObject` (❌ No Delete).

3. **cloudlaunch-visible-only-bucket**
   - Not publicly accessible.
   - `cloudlaunch-user` can only **ListBucket** (see bucket in console).
   - Cannot download or upload files.

---

### ✅ IAM User: `cloudlaunch-user`
- Created with **custom IAM policy** for strict bucket permissions:
  - ListBucket on all three buckets.
  - GetObject on `cloudlaunch-site-bucket`.
  - GetObject + PutObject on `cloudlaunch-private-bucket`.
  - ❌ No DeleteObject anywhere.
  - ❌ No content access to `cloudlaunch-visible-only-bucket`.

- Attached an additional **read-only VPC policy**:
  - Allows listing/viewing VPC, subnets, route tables, and security groups.
  - Ensures user can **observe network design** but not modify it.

📄 Example IAM Policy JSON (`cloudlaunch-user-policy.json`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::cloudlaunch-site-bucket",
        "arn:aws:s3:::cloudlaunch-private-bucket",
        "arn:aws:s3:::cloudlaunch-visible-only-bucket"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::cloudlaunch-site-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::cloudlaunch-private-bucket/*"
    }
  ]
}

📄 Example VPC Read-only Policy (cloudlaunch-vpc-readonly-policy.json):

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}


🌍 Static Website

A simple webpage deployed to cloudlaunch-site-bucket.

📄 Example index.html (unique CloudLaunch branding):

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>🌩️ Welcome to CloudLaunch</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; margin-top: 80px; background: #f4f4f9; }
    h1 { color: #2c3e50; }
    p { font-size: 18px; color: #555; }
    footer { margin-top: 50px; font-size: 14px; color: #777; }
  </style>
</head>
<body>
  <h1>🚀 CloudLaunch Platform</h1>
  <p>Deployed using <strong>AWS S3 + CloudFront</strong></p>
  <p>Secure | Lightweight | Scalable</p>
  <footer>AltSchool Cloud Engineering – Tinyuka 2024</footer>
</body>
</html>

📝 Task 2: VPC Design
✅ VPC: cloudlaunch-vpc

CIDR Block: 10.0.0.0/16

✅ Subnets

Public Subnet: 10.0.1.0/24 (for load balancers, IGW access)

Application Subnet: 10.0.2.0/24 (for private app servers)

Database Subnet: 10.0.3.0/28 (for DB services like RDS)

✅ Internet Gateway

IGW: cloudlaunch-igw

Attached to VPC.

✅ Route Tables

Public Route Table (cloudlaunch-public-rt)

Associated with Public Subnet.

Default route 0.0.0.0/0 → Internet Gateway.

App Route Table (cloudlaunch-app-rt)

Associated with Application Subnet.

No route to internet (fully private).

DB Route Table (cloudlaunch-db-rt)

Associated with Database Subnet.

No route to internet (fully private).

✅ Security Groups

cloudlaunch-app-sg

Allows HTTP (port 80) traffic only inside VPC (10.0.0.0/16).

Egress: allow all outbound.

cloudlaunch-db-sg

Allows MySQL (port 3306) from App Subnet (10.0.2.0/24) only.

Egress: allow all outbound.


🌐 Bonus: CloudFront Distribution

CloudFront sits in front of cloudlaunch-site-bucket.

Provides:

HTTPS (SSL termination).

Global CDN caching for faster site delivery.

