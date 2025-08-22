# 🌐 CloudLaunch Infrastructure — AltSchool Assessment

This repository contains my **Terraform configuration** for the **CloudLaunch project**.  
It demonstrates my understanding of **AWS core services (S3, IAM, VPC)** and also includes a **bonus CloudFront distribution** for HTTPS.

- Name: Gideon Omole
- Student ID: ALT/SOE/024/5235

- cloudlaunch_cloudfront_url = "d2ddu2q97k4cc7.cloudfront.net"
- cloudlaunch_user_password = <sensitive>
- iam_user = "cloudlaunch-user"
- s3_website_url = "cloudlaunch-site-bucket-426300336425.s3-website-eu-west-1.amazonaws.com"
- vpc_id = "vpc-0881c71a081bb2ea2"

---

## 📘 Task 1 — S3 + IAM (Static Website Hosting & User Permissions)

### 🔹 Step 1 — Create Public Website Bucket
- Declared a public S3 bucket:

```hcl
resource "aws_s3_bucket" "site" { ... }
```

- Attached a bucket website configuration:
```hcl
resource "aws_s3_bucket_website_configuration" "site" { ... }
```

- Configured:

 index.html → main page

 error.html → error page

To make it public, I configured Bucket Public Access Block (disabled restrictions) and wrote a Bucket Policy to allow s3:GetObject for everyone:

```hcl
resource "aws_s3_bucket_policy" "site_policy" {
  policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })
}
```
- Uploaded index.html using Terraform:

```hcl
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
```

## 👉 Website URL (HTTP only): http://cloudlaunch-site-bucket-<account_id>.s3-website-eu-west-1.amazonaws.com

<br>
<br>

### Step 2 — Create Private Bucket

- Created another S3 bucket:
```hcl
resource "aws_s3_bucket" "private" { ... }
```

- Configured Block Public Access to ensure:

  - ❌ No public policies

  - ❌ No ACLs

- This bucket is only accessible via IAM permissions.

### 🔹 Step 3 — Create “Visible-Only” Bucket
- Created a third bucket:
```hcl
resource "aws_s3_bucket" "visible_only" { ... }
```
- Blocked public access.
- IAM users can list objects but not read/download them.

<br>
<br>

### 🔹 Step 4 — Create IAM User & Policy
- Declared an IAM user:
```hcl
resource "aws_iam_user" "cloudlaunch_user" {
  name = "cloudlaunch-user"
}
```
- Attached a custom JSON policy (cloudlaunch-user-policy.json) to restrict actions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::cloudlaunch-private-bucket-<account_id>/*"
    },
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject"],
      "Resource": "arn:aws:s3:::cloudlaunch-private-bucket-<account_id>/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::cloudlaunch-visible-only-bucket-<account_id>"
    }
  ]
}

<br>
<br>


```

- Added a login profile with enforced password reset on first login.
```hcl
resource "aws_iam_user_login_profile" "cloudlaunch_user" {
  user    = aws_iam_user.cloudlaunch_user.name
  password_reset_required = true
}
```

<br>
<br>

#### 👉 IAM User Credentials:

- Username: cloudlaunch-user
- Password: (provided separately in console, must reset at first login)
- Console URL:
```
https://<account_alias>.signin.aws.amazon.com/console
```
- Account ID: <your-account-id>

<br>
<br>

### 🔹 Bonus — CloudFront Distribution

- Created a CloudFront distribution in front of the public website bucket:
```hcl
resource "aws_cloudfront_distribution" "cloudlaunch_site_cdn" { ... }
```
This provides:

- ✅ HTTPS (via AWS default SSL cert)

- ✅ Global CDN caching

👉 CloudFront URL (HTTPS-secure): https://d2ddu2q97k4cc7.cloudfront.net/

<br>
<br>

## 📘 Task 2 — VPC Design
### 🔹 Step 1 — Create VPC

Declared a new VPC:
```
resource "aws_vpc" "cloudlaunch" {
  cidr_block = "10.0.0.0/16"
}
```
<br>
<br>

### 🔹 Step 2 — Create Subnets

- Public Subnet → 10.0.1.0/24
- Application Subnet → 10.0.2.0/24
- Database Subnet → 10.0.3.0/28
```hcl
resource "aws_subnet" "public" { ... }
resource "aws_subnet" "app" { ... }
resource "aws_subnet" "db" { ... }
```
<br>
<br>
### 🔹 Step 3 — Internet Gateway & Routes

- Attached an IGW:
```hcl
resource "aws_internet_gateway" "igw" { ... }
```

- Configured Route Tables:

   -  Public RT → routes 0.0.0.0/0 → IGW

   -  Private RTs → no internet route
<br>
<br>

### 🔹 Step 4 — Security Groups

- App SG (cloudlaunch-app-sg)

  - Allows inbound HTTP (80) traffic within the VPC only.

- DB SG (cloudlaunch-db-sg)

  - Allows inbound MySQL (3306) only from the Application Subnet.


📂 Repository Structure
```bash
cloudlaunch/
├── main.tf                        # AWS provider
├── variables.tf                   # Variables
├── s3.tf                          # S3 buckets + policies
├── iam.tf                         # IAM user + policy
├── vpc.tf                         # VPC, subnets, routes, SGs
├── cloudfront.tf                  # CloudFront distribution (bonus)
├── cloudlaunch-user-policy.json   # IAM custom policy
├── screenshots/                   # Screenshots of console (optional)
└── README.md                      # This file
```
<br>
<br>
🖼️ Screenshots 

- AWS Console → Show 3 buckets created

![Alt text](/images/S3%20buckets.png "S3 bucket")

<br>
<br>

- S3 website running in browser (HTTP only)
![Alt text](/images/S3%20HTTP%20only.png "S3 site")

<br>
<br>

- CloudFront distribution URL showing HTTPS secure site

![Alt text](/images/CDN%20site.png "CDN site")
<br>
<br>

- VPC with subnets in AWS Console

![Alt text](/images/VPC.png "CDN site")







