# Inputs to the stack. Values with a `default` are optional; `database_url`
# has none, so Terraform will demand it (we supply it via terraform.tfvars).

variable "region" {
  description = "AWS region for every resource. Set to us-west-2 to co-locate with the Supabase DB (also in us-west-2) and minimize DB round-trip latency."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Name prefix applied to all resources so they're easy to spot."
  type        = string
  default     = "ufcapi"
}

variable "image_tag" {
  description = "Which tag of the ECR image the Lambda should run."
  type        = string
  default     = "latest"
}

variable "database_url" {
  description = "Supabase Postgres connection string. Marked sensitive so it's not printed in plan/apply output."
  type        = string
  sensitive   = true
}

variable "cors_origins" {
  description = "Allowed browser origins. Stays ['*'] until the CloudFront domain exists (Step 4)."
  type        = list(string)
  default     = ["*"]
}

variable "alert_email" {
  description = "Email address that receives the AWS budget alerts."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly spend ceiling (USD) for budget alerts. ALERTS ONLY — AWS does not hard-stop spending at this number."
  type        = number
  default     = 5
}
