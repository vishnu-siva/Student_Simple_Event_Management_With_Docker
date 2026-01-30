# Terraform Remote State Setup

## Problem Fixed
**Before:** Every Jenkins run created a NEW EC2 instance because Terraform state was lost (cleanWs in Jenkinsfile).

**After:** Jenkins reuses the SAME EC2 instance by storing Terraform state in AWS S3.

---

## What Changed

### 1. Remote Backend Configuration
**File:** `terraform/provider.tf`

Added S3 backend block:
```hcl
backend "s3" {
  bucket         = "student-event-terraform-state"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "student-event-terraform-locks"
}
```

### 2. Jenkinsfile Updated
**File:** `Jenkinsfile`

Changed deploy stage:
- Added `terraform init -reconfigure` to connect to S3 backend
- Removed debug statements
- Added output display after deployment

---

## One-Time Setup (Run Once)

### Step 1: Create S3 Bucket and DynamoDB Table

**Option A - Using Script (Recommended):**
```bash
cd terraform
chmod +x setup-remote-state.sh
./setup-remote-state.sh
```

**Option B - Manual AWS CLI:**
```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket student-event-terraform-state \
    --region us-east-1

aws s3api put-bucket-versioning \
    --bucket student-event-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name student-event-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

### Step 2: Migrate Existing State (If Instance Running)

If you have a running instance you want to keep:

```bash
cd terraform

# Backup local state
cp terraform.tfstate terraform.tfstate.backup

# Initialize with remote backend
terraform init -migrate-state

# Verify migration
terraform state list
```

If starting fresh (no instance to keep):
```bash
cd terraform
terraform init -reconfigure
```

### Step 3: Commit and Push

```bash
git add terraform/provider.tf Jenkinsfile terraform/setup-remote-state.sh
git commit -m "Add Terraform remote state backend to prevent instance recreation"
git push origin main
```

---

## How It Works Now

### Before (❌ Problem):
```
Jenkins Run #1:
  → cleanWs deletes workspace
  → terraform init creates fresh state
  → terraform apply sees no existing resources
  → Creates NEW instance (i-abc123)
  
Jenkins Run #2:
  → cleanWs deletes workspace again
  → terraform init creates fresh state again
  → terraform apply sees no existing resources again
  → Creates ANOTHER NEW instance (i-def456)
  
Result: Multiple instances, lost data, wasted money
```

### After (✅ Fixed):
```
Jenkins Run #1:
  → terraform init -reconfigure connects to S3
  → Downloads state from S3
  → terraform apply sees existing instance
  → Updates Docker containers ONLY
  → Uploads new state to S3
  
Jenkins Run #2:
  → terraform init -reconfigure connects to S3
  → Downloads state from S3 (shows existing instance)
  → terraform apply detects no infrastructure changes
  → Updates Docker containers ONLY
  → Same instance reused!
  
Result: ONE instance, persistent data, Elastic IP unchanged
```

---

## Benefits

✅ **Same EC2 instance** across all Jenkins runs  
✅ **Elastic IP never changes** (34.226.92.215)  
✅ **Database data persists** (MySQL volume on same instance)  
✅ **Only Docker images updated** on each deployment  
✅ **Cost savings** (no duplicate instances)  
✅ **State locking** (DynamoDB prevents concurrent modifications)  
✅ **State versioning** (S3 keeps history)  

---

## Verify It's Working

### After First Jenkins Run with New Setup:

1. Check S3 bucket has state file:
```bash
aws s3 ls s3://student-event-terraform-state/
```

2. Check DynamoDB for locks:
```bash
aws dynamodb scan --table-name student-event-terraform-locks --region us-east-1
```

3. Run Jenkins again - should see:
```
terraform plan
...
No changes. Your infrastructure matches the configuration.
```

4. Check AWS Console - should only see ONE instance with ID from first run

---

## Troubleshooting

### Error: "Backend configuration changed"
```bash
cd terraform
terraform init -reconfigure
```

### Error: "Error acquiring state lock"
Wait 5 minutes or force unlock:
```bash
terraform force-unlock <LOCK_ID>
```

### Starting completely fresh
```bash
# Delete all instances manually in AWS Console
# Then delete state:
aws s3 rm s3://student-event-terraform-state/terraform.tfstate
terraform init -reconfigure
terraform apply
```

---

## Cost Note

**S3 Storage:** ~$0.023/month for state file  
**DynamoDB:** Free tier (25 WCU, 25 RCU)  
**Total:** Essentially free, saves $$$ by preventing duplicate instances

---

## Next Jenkins Run

After pushing these changes:
1. Jenkins webhook triggers
2. Builds Docker images (as before)
3. Pushes to DockerHub (as before)
4. **Connects to S3 backend** ✨ NEW
5. **Reuses existing instance** ✨ NEW
6. Updates Docker containers only
7. Frontend shows updated code with correct API

**No more instance recreation!** 🎉
