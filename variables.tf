variable hcloud_token {
  type        = string
  description = "API token for Hetzner Cloud. For security reasons, do not include this value in the source code. Use -var flag or provide as env var named TF_VAR_hcloud_token."
}

variable masters {
  description = "Number of master nodes for the k8s cluster"
  type        = number
  default     = 1
}

variable workers {
  description = "Number of worker nodes for the k8s cluster"
  type        = number
  default     = 2
}

variable instance_type {
  type        = string
  default     = "cax11"
}

variable instance_image {
  type        = string
  default     = "ubuntu-22.04"
}

variable "public_key_file" {
  description = "Path to a public key for ssh as a .pub"
  type        = string
  sensitive   = true
  default     = "~/.ssh/id_rsa.pub"
  validation {
    condition     = length(regexall(".pub", var.public_key_file)) > 0
    error_message = "Public key is empty string or contains invalid characters."
  }
}

variable "labels" {
  description = "Labels for all resources"
  type        = map(string)
  default     = {
    Project     = "k8s",
    managed_by  = "terraform"
  }
}