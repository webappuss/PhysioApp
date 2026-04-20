variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (staging / production)"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "physioconnect"
}

# ── Networking ───────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

# ── EC2 ──────────────────────────────────────────────────────────────────────
variable "api_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "api_ami_id" {
  description = "Amazon Linux 2023 AMI in ap-south-1 (update if needed)"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "physioconnect-key"
}

# ── RDS ──────────────────────────────────────────────────────────────────────
variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_name" {
  type    = string
  default = "physioconnect"
}

variable "db_username" {
  type      = string
  default   = "physio"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# ── ElastiCache ───────────────────────────────────────────────────────────────
variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}

# ── Domain ────────────────────────────────────────────────────────────────────
variable "api_domain" {
  type    = string
  default = "api.physioconnect.in"
}

variable "admin_domain" {
  type    = string
  default = "admin.physioconnect.in"
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (must be in ap-south-1 for ALB, us-east-1 for CloudFront)"
  type        = string
  default     = ""
}

variable "admin_acm_certificate_arn" {
  description = "ACM cert ARN in us-east-1 for CloudFront"
  type        = string
  default     = ""
}

variable "sns_alarm_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications (optional)"
  type        = string
  default     = ""
}
