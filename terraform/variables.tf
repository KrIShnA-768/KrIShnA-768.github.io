variable "region" {
  description = "Region for the S3 bucket. The ACM certificate is pinned to us-east-1 separately."
  type        = string
  default     = "ap-south-1"
}

variable "domain_name" {
  description = "Apex domain, e.g. krishna.dev. No protocol, no www, no trailing slash."
  type        = string

  validation {
    condition     = !can(regex("^(https?://|www\\.)", var.domain_name))
    error_message = "Give the bare apex domain: krishna.dev, not https://www.krishna.dev."
  }
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name. Convention: <domain>-site, e.g. krishna-dev-site."
  type        = string
}
