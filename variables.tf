variable "allowed_cidr" {
  type        = string
  default     = "127.0.0.1/32" # Replace with your IP
  description = "CIDR range to allow network access from"
}

variable "fault_domain_count" {
  type        = number
  default     = 2
  description = "Number of fault domains in selected location"
}

variable "location" {
  type        = string
  default     = "Australia East"
  description = "Location to create resources in"
}

variable "prefix" {
  type        = string
  default     = "ubuntu"
  description = "Common prefix for resource names"
}
