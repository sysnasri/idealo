# Reusable Cloud Storage Platform Module 

This repository contains a reusable, self-service infrastructure blueprint designed for product teams to securely store file uploads. Built with a focus on simplicity, usability, and cost optimization, it abstracts complex AWS configurations into a clean interface.

## Architecture Overview

The architecture relies entirely on native, serverless AWS services to minimize operational overhead and maximize reliability:


### Architecture Decisions: "Why" vs. "Why Not"

* **Terragrunt over Raw Terraform:** Terragrunt is used to keep backend configurations and provider blocks strictly DRY (Don't Repeat Yourself). It allows the platform team to maintain a single canonical module while enabling product teams to instantiate environments (dev, prod) with minimal configurations.
* 
**S3 Lifecycle Policies for Cost Compliance:** Files are deleted after 30 days.


* 
**EventBridge + SNS for Lightweight Automation:** Instead of provisioning a heavy Lambda function to scan objects, S3 is configured to route `ObjectCreated` events straight to **Amazon EventBridge**. An EventBridge rule filters these events for non-compliant payloads (e.g., matching a disallowed extension ). Once matched, EventBridge fans out to 1 target:


 An **SNS Topic** to instantly push warnings to team endpoints (Slack, email, or PagerDuty) without running any compute code.


---


## Production Readiness: Next Steps

Before rolling this out to a live production environment with real-world workloads, the following enhancements are prioritized:

1. 
**Multi-Account Strategy:** Transition from a single account to an AWS Organizations topology (e.g., `Core-Infra`, `Staging`, `Production`). The Terragrunt layout would be refactored to parse `account_id` contexts dynamically via root-level `.hcl` inheritance.


## my Concerns: 

  1. Application shouldn't use static authentication 
  2. Application/Client should use aws s3 signed url in frontend. 
  3. s3 Object should be moved to long term storage and keep for 1 year for compliences
  4. For Cost optimization, I usualy avoid Lambda and CloudWatch here. instead we can use the app as cronJob inside k8s if there is one. 

---
## My suggestions and Improvements. 

1. Using Terramate integration with Terragrunt in CI 
2. Github OIDC with AWS and seprate Environments for each deployment
3. Write Terragrun plan output into github commit
4. Github Cache to cache terraform binaries.

## CI/CD Pipeline (GitHub Actions)

The automation workflow validates code quality and runs predictable deployment phases:

* **On Pull Request:** Runs `terraform fmt -check`, `tflint`, and a `terragrunt run-all plan` to show the infrastructure delta without making changes.
* **On Merge to Main:** Executes `terragrunt run-all apply --terragrunt-non-interactive` to safely deploy the infrastructure updates to the target AWS environment.

---

AI Tooling Document 

1. Tools Used 

* **Gemini/claudeAI:** Used for generating base configurations, drafting the EventBridge pattern matching blocks, and scaffolding the boilerplate GitHub Actions workflows.

2. Suboptimal Initial Suggestions 

* 
**The Issue:** The AI's first instinct for the "detect non-compliant uploads" requirement was to write a Python-based AWS Lambda function triggered by S3 bucket notifications to scan objects.


* 
**The Correction:** This violated the instruction to keep automation *proportional to the problem* and avoid an overkill pipeline. I rejected the Lambda approach and shifted the design to direct S3-to-EventBridge routing. Leveraging EventBridge patterns to route issues natively to CloudWatch and SNS achieved the exact same alerting goal with zero code to maintain.



3. Failed Prompting & Adjustment 

* **Initial Prompt (Failed):** *"Write a terraform module for an S3 bucket that alerts on wrong file uploads."*
* *Result:* The AI generated a massive, brittle stack involving Lambda layers, object scanning scripts, and heavy IAM roles that would take hours to maintain.


* **Adjusted Prompt (Succeeded):** *"Write a lightweight Terraform configuration utilizing native S3 Event Notifications to send object metadata directly to EventBridge. Show how an EventBridge Rule can match a specific prefix failure and log it to a CloudWatch log group and trigger an SNS topic alert without using compute."*

4. Takeaway on AI in Platform Engineering 

* **Where it helps:** AI is unmatched at writing syntax boilerplate, regex filters, IAM policies, and basic CI/CD pipeline structures, shaving off hours of typing.
* 
**Where it gets in the way:** It defaults heavily to over-engineering. If asked to solve an architectural problem, it leans toward complex, multi-service setups rather than elegant, simple, built-in cloud platform features. The engineer must act as a strict editor to keep the architecture lean.