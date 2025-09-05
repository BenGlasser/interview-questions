# Copilot Instructions for Interview Questions Repository

This repository is a **curated collection of technical interview questions and practical tasks** organized by technology stack. Understanding this structure and purpose is essential for making meaningful contributions.

## Repository Architecture

### Content Organization Pattern
- Each technology has its own directory (`python/`, `bash/`, `gh_actions/`, `terraform-task/`)
- Interview content follows a **question → solution → rubric** pattern
- Senior-level content includes both `questions.md` and `scorecard.md` for complete evaluation workflows
- Terraform tasks include both infrastructure code and task instructions

### Key Content Types
1. **Interview Questions**: Structured with clear rubrics using 1-3 scoring (Poor/Fair/Excellent)
2. **Practical Tasks**: Like `terraform-task/` - complete hands-on exercises with detailed requirements
3. **Evaluation Tools**: Scorecards with specific criteria and comment sections for interviewers

## Content Standards & Patterns

### Question Format (see `senior/fullstack/questions.md`)
```markdown
### [Number]. [Topic Name]
**Question**: [Clear, specific question]
**Rubric**:
- [ ] **Poor** – [Specific inadequate response criteria]
- [ ] **Fair** – [Basic competency indicators]
- [ ] **Excellent** – [Deep expertise indicators with specific examples]
```

### Terraform Module Structure (`terraform-task/`)
- Root-level orchestration in `main.tf` calling modules with `./modules//[service]` pattern
- Each module has dedicated directory: `vpc/`, `ec2/`, `s3/`, `route53/`
- Variables follow environment-specific patterns with type declarations
- Tasks specify exact AWS region (`ap-southeast-1`) and precise networking (`192.168.50.0/16`)

### Scoring System
Consistent **1-3 scale** across all interview materials:
- **1 = Poor**: Incomplete/incorrect
- **2 = Fair**: Basic understanding with gaps  
- **3 = Excellent**: Deep expertise with examples

## Technology-Specific Conventions

### Senior Fullstack Focus
Questions emphasize **performance at scale**: React virtualization, Node.js async patterns, MySQL optimization for large datasets. Always include real-world scenarios (e.g., "thousands of items", "under load").

### Infrastructure Tasks
Terraform challenges require **modular architecture** with separate modules per AWS service. Include security requirements (S3 encryption, IAM policies) and specific networking configurations.

### Code Examples
Python/Bash solutions include **multiple approaches**: basic solution + enhanced version with validation/error handling.

## When Contributing

- **Interview Questions**: Include specific technology versions and realistic scenarios
- **Scoring Rubrics**: Define concrete technical indicators, not subjective qualities
- **Practical Tasks**: Specify exact requirements (regions, IP ranges, resource types)
- **Example Solutions**: Show both basic and production-ready approaches

Focus on **actionable, assessable content** that helps interviewers distinguish between competency levels through specific technical knowledge demonstration.
