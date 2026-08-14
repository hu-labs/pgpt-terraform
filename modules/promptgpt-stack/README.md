# PromptGPT stack module

This module creates the core AWS deployment for a PromptGPT environment: S3-hosted frontend, CloudFront distribution, API Gateway, Lambda, IAM roles, ACM validation, and GitHub Actions OIDC access.

It is mostly a standard Terraform layout, but there are a couple of important deployment quirks worth knowing before a first-time rollout.

## Key Notes

### 1) The first Lambda deployment is intentionally a placeholder

The Lambda resource is created from the `lambda-placeholder/` folder instead of the real app bundle. The module intends to create:

- the Lambda function and aliases
- API Gateway permissions
- stage wiring
- the rest of the stack

without needing the real backend artifact to exist yet. The app code is expected to be published later by CI/CD, and the Terraform code explicitly ignores the `filename` and `source_code_hash` values so external deployment pipelines can manage the code.


### 2) CloudFront rewrites the public API path

The CloudFront function in `cloudfront/rewrite-api-v1-to-prod.js` is a small but important compatibility layer.

The frontend and app config expect to call URLs like:

- `/api/v1/chat`

but the backend API Gateway is exposed under stage paths like:

- `/prod/chat`
- `/test/chat`

Only `/prod/...` is renamed to `/api/v1/...` to give the public URL a stable shape for potential future growth.


### 3) API Gateway is stage-aware and alias-aware

The API Gateway setup uses:

- `test` stage -> `aws_lambda_alias.test`
- `prod` stage -> `aws_lambda_alias.stable`

and also injects a generated API key through CloudFront to the backend origin. The CloudFront distribution is configured to send the API key as `X-Api-Key`, and the API Gateway usage plan/key are bound together so that the public API path works behind the CDN.

### 4) The stack expects a valid public domain and certificate flow

This module wires CloudFront to a custom domain through ACM validation. It expects the domain, ACM certificate validation, and the external DNS records to exist and complete.

### 5) Terraform is only part of the lifecycle

This module defines AWS resources, but the actual backend function versioning is deliberately handled outside Terraform. The code is set up for a deployment model where:

- Terraform builds the platform
- CI/CD publishes the real Lambda artifacts
- Lambda aliases and versions are then switched by the pipeline

That makes the module easier to integrate into preview/prod deployment flows.
