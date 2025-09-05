# Terraform Challenge Solution

⚠️ **SPOILER ALERT**: This document contains the complete solution to the challenge. Try solving it yourself first!

---

## TL;DR - The Root Cause

The **App Runner VPC Connector is placed in subnets whose Network ACLs DENY outbound traffic to Redis on port 6379**.

**Quick Fix**: Move the VPC Connector to the data subnets OR fix the NACL rules.

---

## Detailed Analysis

### The Misconfiguration

In `infra/network.tf`, the app subnet NACL has explicit DENY rules:

```hcl
# NACL for App Subnets (BLOCKS Redis traffic!)
resource "aws_network_acl" "app" {
  # ... other rules ...
  
  # THE BUG: These rules block Redis connections!
  egress {
    rule_no    = 90  # Lower number = higher priority
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "10.0.11.0/24"  # data subnet 1
    from_port  = 6379
    to_port    = 6379
  }

  egress {
    rule_no    = 91
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "10.0.12.0/24"  # data subnet 2
    from_port  = 6379
    to_port    = 6379
  }

  # This ALLOW rule comes AFTER the DENY rules, so it doesn't help
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
}
```

### Why This Breaks Connectivity

1. **App Runner VPC Connector** is placed in **app subnets** (10.0.1.0/24, 10.0.2.0/24)
2. **Redis cluster** is in **data subnets** (10.0.11.0/24, 10.0.12.0/24)
3. When App Runner tries to connect to Redis:
   - Traffic originates from VPC Connector ENIs in app subnets
   - **App subnet NACL** evaluates egress rules
   - **Rule 90/91 DENY** takes precedence over rule 100 ALLOW
   - Connection to Redis port 6379 is **blocked**

### Why Security Groups Don't Help

Security groups are evaluated **after** NACLs:
1. NACL (subnet level) → **BLOCKS HERE** ❌
2. Security Group (ENI level) → never reached
3. Application → never reached

---

## Solution Options

### Option 1: Move VPC Connector (Recommended)

Change the VPC Connector to use data subnets instead of app subnets.

**File**: `infra/apprunner.tf`

```diff
 resource "aws_apprunner_vpc_connector" "main" {
   vpc_connector_name = "${var.project_name}-vpc-connector"
-  subnets           = aws_subnet.app[*].id  # BUG: Uses app subnets
+  subnets           = aws_subnet.data[*].id # FIX: Use data subnets
   security_groups   = [aws_security_group.vpc_connector.id]
 
   tags = {
     Name = "${var.project_name}-vpc-connector"
   }
 }
```

**Why this works**:
- VPC Connector ENIs are now in data subnets
- Data subnet NACLs allow Redis traffic (no DENY rules)
- App Runner can connect to Redis in the same subnets

### Option 2: Fix NACL Rules

Remove or modify the DENY rules in the app subnet NACL.

**File**: `infra/network.tf`

```diff
 resource "aws_network_acl" "app" {
   # ... other rules ...
   
-  # Remove these DENY rules:
-  egress {
-    rule_no    = 90
-    protocol   = "tcp"
-    action     = "deny"
-    cidr_block = "10.0.11.0/24"
-    from_port  = 6379
-    to_port    = 6379
-  }
-
-  egress {
-    rule_no    = 91
-    protocol   = "tcp"
-    action     = "deny"
-    cidr_block = "10.0.12.0/24"
-    from_port  = 6379
-    to_port    = 6379
-  }
 
   # Keep the allow-all rule
   egress {
     rule_no    = 100
     protocol   = "-1"
     action     = "allow"
     cidr_block = "0.0.0.0/0"
   }
 }
```

**Why this works**:
- Removes the explicit DENY rules
- Allow-all rule (100) now takes effect
- Redis traffic flows normally

---

## Implementation Steps

### Step 1: Apply the Fix

Choose one of the solutions above and modify the Terraform code.

```bash
cd infra/

# Make your changes to the Terraform files
# Then apply:
terraform plan
terraform apply
```

### Step 2: Wait for App Runner to Update

App Runner takes 5-10 minutes to redeploy after VPC Connector changes:

```bash
# Monitor the service status
aws apprunner describe-service --service-arn $(terraform output -raw app_runner_service_arn) --query 'Service.Status'

# Wait for status to return to "RUNNING"
```

### Step 3: Test the Fix

```bash
# Test health endpoint
curl $(terraform output -raw app_runner_url)/health

# Should now return:
# {"status":"healthy","redis":"ok",...}

# Test Redis operations
curl "$(terraform output -raw app_runner_url)/set?key=test&value=success"
curl "$(terraform output -raw app_runner_url)/get?key=test"
```

---

## Understanding Network ACLs

### Key Concepts

1. **Stateless**: Unlike security groups, NACLs don't track connection state
2. **Rule Precedence**: Lower rule numbers have higher priority
3. **Explicit Deny**: DENY rules override ALLOW rules with higher numbers
4. **Subnet Level**: Apply to all traffic entering/leaving subnets
5. **Both Directions**: Must allow both request and response traffic

### NACL vs Security Groups

| Aspect | Network ACLs | Security Groups |
|--------|-------------|----------------|
| **Level** | Subnet | Instance/ENI |
| **State** | Stateless | Stateful |
| **Default** | Allow all | Deny all |
| **Rules** | Allow + Deny | Allow only |
| **Evaluation** | First (outer) | Second (inner) |

### Why Route Tables Aren't the Issue

In this challenge, routing is NOT the problem because:
- All subnets are in the same VPC (10.0.0.0/16)
- VPC has an implicit "local" route for the entire CIDR
- Traffic between 10.0.1.x and 10.0.11.x routes locally
- The issue is **filtering** (NACLs), not **routing**

---

## Debugging Techniques Used

### 1. Layer-by-Layer Analysis

```
Application (App Runner) ✓
    ↓
Security Groups ✓ (correct rules)
    ↓  
Network ACLs ❌ (BLOCKS HERE)
    ↓
Routing ✓ (local routes)
    ↓
Destination (Redis) ✓
```

### 2. Traffic Flow Tracing

```
App Runner Service
    ↓
VPC Connector (in app subnets)
    ↓
App Subnet NACL Egress Rules
    ↓ DENIED by rules 90/91
Redis (in data subnets) ❌
```

### 3. Configuration Comparison

- **Working path**: data-subnet → data-subnet (same NACL, allows traffic)
- **Broken path**: app-subnet → data-subnet (different NACLs, blocks traffic)

---

## Common Troubleshooting Mistakes

### ❌ **"Security groups must be wrong"**
- Security groups were correctly configured
- Easy to blame because they're more commonly misconfigured
- Remember: NACLs are evaluated first!

### ❌ **"Redis authentication is the issue"**
- Redis AUTH was intentionally disabled
- Connection errors occur before authentication
- Network connectivity ≠ application authentication

### ❌ **"Route tables need fixing"**
- Intra-VPC routing is automatic (local routes)
- No custom routes needed between subnets in same VPC
- Routing delivers packets; NACLs filter them

### ❌ **"IAM permissions are missing"**
- IAM controls API access, not network connectivity
- App Runner service was running (IAM was correct)
- Network layer issue, not permissions issue

---

## Production Considerations

### Best Practices

1. **Principle of Least Privilege**: Use specific ALLOW rules instead of DENY rules
2. **Subnet Design**: Group resources with similar network requirements
3. **NACL Simplicity**: Keep NACL rules simple; use Security Groups for fine-grained control
4. **Testing**: Always test network connectivity after infrastructure changes

### Monitoring

```bash
# VPC Flow Logs can help debug NACL issues
aws ec2 describe-flow-logs --filter Name=resource-id,Values=<subnet-id>

# CloudWatch metrics for connection failures
aws logs filter-log-events --log-group-name /aws/apprunner/... --filter-pattern "ERROR"

# App Runner service metrics
aws cloudwatch get-metric-statistics --namespace AWS/AppRunner --metric-name RequestCount
```

---

## Key Learning Points

1. **Network Layer Order**: NACLs → Security Groups → Application
2. **Stateless vs Stateful**: NACLs require bidirectional rules
3. **Rule Precedence**: Lower numbers = higher priority in NACLs
4. **Subnet Placement Matters**: VPC Connector subnet choice affects which NACLs apply
5. **Systematic Debugging**: Test each layer individually

---

## Challenge Variations

This challenge could be modified to test other scenarios:

- **Route Table Issues**: Remove local routes or add incorrect next-hops
- **Security Group Misconfigurations**: Wrong port ranges or source/destination rules
- **DNS Resolution**: Use wrong Redis endpoint or DNS resolution issues
- **IAM Permissions**: Remove ECR pull permissions or instance profile issues
- **Redis Authentication**: Enable AUTH with wrong credentials

The NACL misconfiguration was chosen because:
- It's a realistic production issue
- Commonly overlooked in favor of Security Groups
- Tests understanding of AWS networking layers
- Requires systematic debugging approach

---

*Congratulations on solving the challenge! You now have hands-on experience with AWS networking troubleshooting and understand the subtle but critical role of Network ACLs in VPC connectivity.*