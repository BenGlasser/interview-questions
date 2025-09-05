You are an expert DevOps/Cloud instructor. Create a self-contained, hands-on Terraform challenge repository that simulates a realistic AWS troubleshooting scenario.

## Goal
Provision an AWS **App Runner** service (containerized sample app) and an **ElastiCache for Redis** cluster in a VPC with all required networking. Intentionally ship the repo with a misconfiguration in the **App Runner VPC Connector subnet/NACL setup** that prevents the App Runner service from connecting to Redis. The candidate must investigate, identify the root cause, and fix it.

## Specific Root Cause (Bug #2 pinned)
- The **App Runner VPC Connector** is attached to **“app subnets”** whose **Network ACLs (NACLs)** block traffic to the **Redis “data subnets”** on port **6379** (and/or block the return ephemeral ports).
- Everything else (security groups, Redis auth, env vars) is correct, so the failure is strictly due to **subnet/NACL selection/rules**.
- Keep both App Runner and Redis **in the same VPC**. Do **not** rely on route tables to break connectivity (intra-VPC routing is always “local”); the breakage must be caused by **NACLs on the subnets** the connector uses (and/or the data subnets).

## Deliverables (Repository Structure)
- `README.md`: concise, step-by-step instructions to:
  - Prereqs: Terraform ≥ 1.6, AWS CLI v2, Docker, jq
  - Setup: `terraform init/plan/apply` with default region `us-east-1`
  - Build & push the demo app image (or use a provided public ECR image)
  - Scenario brief and success criteria (HTTP endpoint returns Redis-backed health)
  - Where to see App Runner logs (Console + CLI examples)
  - Cost notes and teardown (`terraform destroy`) warning in bold
  - **Hints** section (progressive) focused on VPC connector subnets and NACLs (see below)
- `infra/` Terraform code:
  - `providers.tf`, `versions.tf`, `variables.tf`, `outputs.tf`
  - `network.tf`: VPC (10.0.0.0/16), two **app subnets** (10.0.1.0/24, 10.0.2.0/24), two **data subnets** (10.0.11.0/24, 10.0.12.0/24), IGW, private layout ok; NAT optional but not required.
  - **NACLs**:
    - `app_nacl` attached to **app subnets** with rules that **DENY egress to TCP/6379** to the data subnets (and/or DENY ephemeral return traffic).
    - `data_nacl` attached to **data subnets** with an **overly strict inbound** rule set that **DENIES inbound 6379** from the app subnets’ CIDRs (or a higher-priority DENY before the ALLOW).
    - Ensure the misconfiguration is subtle but deterministic (e.g., an explicit DENY rule with a lower rule number than the ALLOW).
  - `redis.tf`: ElastiCache for Redis (cluster mode disabled, 1 node) in the **data subnets**; security group allows TCP/6379 **from the App Runner connector SG** (so SGs are correct).
  - `apprunner.tf`:
    - ECR repo (or use a public image), IAM roles/policies for App Runner & ECR pulls (least privilege).
    - App Runner **VPC Connector** attached to the **app subnets** (the mis-selected subnets) and the connector’s **own SG**.
    - App Runner service with env vars: `REDIS_HOST`, `REDIS_PORT=6379`, optional `REDIS_PASSWORD` if auth is on (can be off for simplicity), `REDIS_TLS=false`.
  - `variables.tf`: region, name prefix, instance sizes, CIDRs (with validation), booleans for optional features.
  - `outputs.tf`: App Runner URL, Redis primary endpoint/port, connector subnet IDs, connector SG ID, Redis SG ID, NACL IDs, and subnet CIDRs for clarity.
  - **Important**: Security groups must be correct so candidates naturally pivot to **subnet/NACL** analysis.
- `app/` sample service:
  - Minimal Node.js or Python HTTP server with:
    - `GET /health` → try Redis `PING`; return `{ "redis":"ok" }` on success or JSON error on failure (include underlying error message).
    - Optional `GET /set?key=...&value=...` and `GET /get?key=...`.
  - `Dockerfile` (small base).
- `scripts/` (optional):
  - `build_and_push.sh` for container.
  - `check.sh` to curl `/health` repeatedly and pretty-print.
- `challenge/`:
  - `TASKS.md`: investigation tasks and acceptance criteria.
  - `SOLUTION.md`: deep dive into the **NACL** root cause and the exact fixes, hidden under “Spoilers.”
  - A `solution` branch (or tag) with the corrected Terraform diff.

## Candidate Workflow (document clearly in README)
1) `terraform apply` and wait for App Runner to stabilize.
2) Visit **App Runner URL** → `/health` initially fails with a Redis connection error (timeout/refused).
3) Fetch App Runner logs (Console + CLI):
   - `aws apprunner list-services`
   - `aws apprunner list-operations --service-arn ...`
4) Inspect **VPC connector** details & ENIs:
   - `aws apprunner list-vpc-connectors`
   - `aws ec2 describe-network-interfaces --filters Name=group-id,Values=<connector-sg-id>`
5) Confirm **ElastiCache** endpoint/port from Terraform outputs.
6) Validate **Security Groups** (they **are** correct):
   - `aws ec2 describe-security-groups --group-ids <redis-sg-id> <connector-sg-id>`
7) Investigate **NACLs and Subnets** (the real problem):
   - `aws ec2 describe-network-acls --network-acl-ids <app-nacl-id> <data-nacl-id>`
   - Show rules; note stateless behavior (must allow on both inbound & outbound).
   - Compare rules against **app subnet CIDRs** and **data subnet CIDRs**; identify **DENY** that blocks TCP/6379 and/or ephemeral return ports.
8) Apply Fix (see below) → `terraform apply` → `/health` now returns success.

## The Fix (what the candidate should change)
- Option A (preferred): **Move the VPC Connector** to the **data subnets** (or to app subnets whose NACLs allow traffic) by updating the connector’s `subnets = [...]` in Terraform.
- Option B: **Adjust NACL rules** to allow:
  - **Inbound on data subnets**: ALLOW TCP/6379 from app subnets’ CIDRs; ALLOW ephemeral (1024–65535 or 32768–65535) back.
  - **Outbound on app subnets**: ALLOW TCP/6379 to data subnets’ CIDRs and ALLOW ephemeral back.
- Keep SGs unchanged to reinforce that the issue was the subnet/NACL layer.

## Hints (progressive, in README)
1) “Intra-VPC routing is ‘local.’ If security groups look right, what else could block traffic between subnets?”
2) “Check the **App Runner VPC Connector** subnets and their **NACLs**.”
3) “Remember NACLs are **stateless**; you must allow both the request (6379) **and** the return ephemeral ports.”
4) “Does the **data subnet NACL** allow inbound 6379 from the **app subnets’ CIDRs**?”
5) “Try moving the connector to the **data subnets**; if that works, compare the NACLs.”

## Terraform Quality & Constraints
- Use official AWS provider resources (VPC, subnets, NACLs, SGs, App Runner service & VPC connector, ECR, ElastiCache).
- No hardcoded secrets. Prefer Redis without AUTH for this scenario (or wire a password via SSM Parameter Store if you include auth; keep it correct so auth isn’t the issue).
- Reasonable defaults (t3/t4g small; 1 Redis node).
- Provide `terraform.tfvars.example`.
- `terraform fmt` compliance; least-privilege IAM.
- Outputs include IDs and CIDRs that make network debugging easier.

## Solution Branch
- Include a `solution` branch (or tag) that:
  - Moves the VPC connector to **data subnets** **or** fixes the **NACLs** (choose one primary fix and explain both options).
  - Shows exact Terraform diffs.
  - `SOLUTION.md` explains why route tables weren’t the issue, how NACL DENY precedence works, and ephemeral port ranges.

## Testing Instructions
- After initial deploy, `/health` fails with a connection timeout/refused (include the error surfaced by the app).
- After the fix, `/health` returns `{"redis":"ok"}` and optional `/set`/`/get` work.

## Teardown
- Prominent section in README on `terraform destroy` and verifying no lingering costs (ECR images, ElastiCache).

## Output Format
Output the full repository as markdown with a file tree and complete contents of each file, ready for copy/paste. Keep README concise but complete. Ensure the only root cause is the **misconfigured VPC connector subnets / NACL rules**, solvable within ~60–90 minutes.
