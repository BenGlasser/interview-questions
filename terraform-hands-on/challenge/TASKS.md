# Terraform Troubleshooting Challenge - Investigation Tasks

This document provides a structured approach to investigating and solving the Redis connectivity issue in the App Runner service.

## Background

You have deployed an App Runner service that should connect to an ElastiCache Redis cluster within a VPC. The `/health` endpoint should return `{"redis":"ok"}`, but instead it returns connection errors.

## Acceptance Criteria

✅ **Primary Goal**: The `/health` endpoint returns a successful response with `"redis":"ok"`

✅ **Secondary Goals**:
- `/set?key=test&value=hello` works
- `/get?key=test` returns the stored value
- Application logs show successful Redis connections

## Investigation Tasks

### Task 1: Confirm the Problem

**Objective**: Establish that the issue exists and understand the symptoms.

**Steps**:
1. Get the App Runner service URL from Terraform outputs
2. Test the health endpoint and document the exact error message
3. Check if other endpoints (`/`, `/set`, `/get`) are accessible

**Commands**:
```bash
cd infra/
terraform output app_runner_url
curl $(terraform output -raw app_runner_url)/health
curl $(terraform output -raw app_runner_url)/
```

**Expected Results**:
- `/health` returns HTTP 500 with Redis connection error
- `/` returns HTTP 200 with service information
- Error message should mention connection timeout or refused

---

### Task 2: Examine Application Logs

**Objective**: Get detailed error information from the App Runner service logs.

**Steps**:
1. Find the App Runner service ARN
2. Access logs via AWS Console or CLI
3. Look for Redis connection attempts and error details

**Commands**:
```bash
# Get service information
aws apprunner list-services
aws apprunner describe-service --service-arn <service-arn>

# Find log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/apprunner"

# Get recent logs
aws logs describe-log-streams --log-group-name "/aws/apprunner/<service-name>/<service-id>/application" --order-by LastEventTime --descending
aws logs get-log-events --log-group-name "/aws/apprunner/<service-name>/<service-id>/application" --log-stream-name "<stream-name>"
```

**What to Look For**:
- Connection timeout errors to Redis
- Network connectivity issues
- Specific error codes (ECONNREFUSED, ETIMEDOUT, etc.)

---

### Task 3: Validate Infrastructure Components

**Objective**: Confirm that all infrastructure components are properly configured.

**Steps**:
1. Verify Redis cluster is running and healthy
2. Check App Runner service status
3. Confirm VPC Connector is active

**Commands**:
```bash
# Check Redis status
aws elasticache describe-cache-clusters --cache-cluster-id $(terraform output -raw redis_cluster_id) --show-cache-node-info

# Check App Runner service
aws apprunner describe-service --service-arn $(terraform output -raw app_runner_service_arn)

# Check VPC Connector
aws apprunner list-vpc-connectors
aws apprunner describe-vpc-connector --vpc-connector-arn $(terraform output -raw vpc_connector_arn)
```

**Expected Results**:
- Redis cluster status: "available"
- App Runner service status: "RUNNING" 
- VPC Connector status: "ACTIVE"

---

### Task 4: Investigate Security Groups (Red Herring)

**Objective**: Verify security group configurations (these should be correct).

**Steps**:
1. Examine Redis security group rules
2. Examine VPC Connector security group rules
3. Confirm they allow communication on port 6379

**Commands**:
```bash
# Redis security group
aws ec2 describe-security-groups --group-ids $(terraform output -raw redis_security_group_id)

# VPC Connector security group
aws ec2 describe-security-groups --group-ids $(terraform output -raw connector_security_group_id)
```

**Expected Results**:
- Redis SG allows inbound 6379 from Connector SG ✅
- Connector SG allows outbound 6379 to Redis SG ✅
- Security groups are NOT the problem!

---

### Task 5: Examine VPC Connector Placement

**Objective**: Understand which subnets the VPC Connector is using.

**Steps**:
1. Identify the subnets used by the VPC Connector
2. Compare with available subnet types (app vs data)
3. Check the network interfaces created by the connector

**Commands**:
```bash
# Get connector subnet details
terraform output connector_subnet_ids
terraform output app_subnet_cidrs
terraform output data_subnet_cidrs

# Examine the connector's network interfaces
aws ec2 describe-network-interfaces --filters Name=group-id,Values=$(terraform output -raw connector_security_group_id)
```

**Key Questions**:
- Which subnets is the VPC Connector using?
- Are these the "app" subnets (10.0.1.0/24, 10.0.2.0/24) or "data" subnets (10.0.11.0/24, 10.0.12.0/24)?
- Where is Redis located?

---

### Task 6: Investigate Network ACLs (The Root Cause!)

**Objective**: Examine Network ACL rules that might be blocking traffic.

**Steps**:
1. Identify which NACLs are associated with each subnet type
2. Examine the rules in detail
3. Check for DENY rules that might block Redis traffic

**Commands**:
```bash
# Get NACL IDs
terraform output app_nacl_id
terraform output data_nacl_id

# Examine app subnet NACLs (where the connector is)
aws ec2 describe-network-acls --network-acl-ids $(terraform output -raw app_nacl_id)

# Examine data subnet NACLs (where Redis is)
aws ec2 describe-network-acls --network-acl-ids $(terraform output -raw data_nacl_id)

# Get subnet associations
aws ec2 describe-subnets --subnet-ids $(terraform output -raw connector_subnet_ids | jq -r '.[]')
aws ec2 describe-subnets --subnet-ids $(terraform output -raw data_subnet_ids | jq -r '.[]')
```

**What to Look For**:
- **DENY rules** with lower numbers (higher priority) than ALLOW rules
- Rules blocking port **6379** from app subnets to data subnets
- Rules blocking **ephemeral ports** (32768-65535) for return traffic
- Remember: **NACLs are stateless** - both directions must be allowed!

---

### Task 7: Analyze the Traffic Flow

**Objective**: Understand the complete network path and identify the blocking point.

**Traffic Flow**:
1. App Runner service (in VPC Connector subnets)
2. → VPC Connector ENIs (in app subnets: 10.0.1.0/24, 10.0.2.0/24)
3. → **App Subnet NACL Rules** 🚫 (BLOCKS HERE!)
4. → Data subnet (10.0.11.0/24, 10.0.12.0/24)
5. → Redis cluster

**Key Questions**:
- Does the **app subnet NACL** allow **outbound** traffic to port 6379 in data subnets?
- Does the **app subnet NACL** allow **inbound** ephemeral ports for return traffic?
- Does the **data subnet NACL** allow **inbound** traffic from app subnets on port 6379?

---

### Task 8: Identify the Fix

**Objective**: Determine the correct solution approach.

**Option A: Move the VPC Connector** (Recommended)
```hcl
# In apprunner.tf, change:
resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.project_name}-vpc-connector"
  subnets           = aws_subnet.data[*].id  # Use data subnets instead!
  security_groups   = [aws_security_group.vpc_connector.id]
}
```

**Option B: Fix the NACL Rules**
```hcl
# Remove or modify the DENY rules in network.tf:
# Comment out or change rule numbers 90 and 91 in app_nacl
```

**Test the Fix**:
1. Apply the Terraform changes
2. Wait for App Runner to redeploy (~5-10 minutes)
3. Test the `/health` endpoint again

---

## Verification

Once you've implemented a fix:

```bash
# Test the endpoints
curl $(terraform output -raw app_runner_url)/health
curl "$(terraform output -raw app_runner_url)/set?key=challenge&value=completed"
curl "$(terraform output -raw app_runner_url)/get?key=challenge"

# Check the logs for successful connections
aws logs get-log-events --log-group-name "/aws/apprunner/<service-name>/<service-id>/application" --log-stream-name "<stream-name>" --start-time $(date -d '5 minutes ago' +%s)000
```

**Success Indicators**:
- `/health` returns `{"redis":"ok"}`
- Set/get operations work correctly
- Logs show "Connected to Redis" messages
- No more connection timeout errors

---

## Learning Objectives

After completing this challenge, you should understand:

1. **Network ACL Behavior**: How NACLs are stateless and require rules for both directions
2. **VPC Connector Placement**: How the choice of subnets affects network connectivity
3. **AWS Networking Layers**: The order of evaluation (NACLs → Security Groups → Application)
4. **Troubleshooting Methodology**: How to systematically investigate network connectivity issues
5. **Infrastructure as Code**: How small configuration changes can have significant impacts

---

## Time Estimate

- **Investigation Phase**: 30-45 minutes
- **Root Cause Identification**: 15-30 minutes  
- **Fix Implementation**: 10-15 minutes
- **Total**: 60-90 minutes

Good luck! Remember: the issue is NOT with security groups, IAM roles, or Redis configuration. Focus on the networking layer between the VPC Connector and Redis.