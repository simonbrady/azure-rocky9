variable "allowed_cidr" {
  type        = string
  default     = "127.0.0.1/32" # Replace with your IP
  description = "CIDR range to allow network access from"
}

variable "location" {
  type        = string
  default     = "Australia East"
  description = "Location to create resources in"
}

variable "prefix" {
  type        = string
  default     = "rocky9"
  description = "Common prefix for resource names"
}
