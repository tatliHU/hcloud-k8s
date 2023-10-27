variable hcloud_token {
  type        = string
  description = "API token for Hetzner Cloud. For security reasons, do not include this value in the source code. Use -var flag or provide as env var named TF_VAR_hcloud_token."
}

variable masters {
  description = "Number of master nodes for the k8s cluster."
  type        = number
  default     = 1
  validation {
    condition     = var.masters > 0
    error_message = "Number of master nodes should be bigger than zero."
  }
  validation {
    condition     = var.masters < 4
    error_message = "Too many master nodes."
  }
}

variable workers {
  description = "Number of worker nodes for the k8s cluster."
  type        = number
  default     = 2
  validation {
    condition     = var.workers > 0
    error_message = "Number of worker nodes should be bigger than zero."
  }
  validation {
    condition     = var.workers < 10
    error_message = "Too many worker nodes."
  }
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
  description = "Path to a public key for ssh as a .pub."
  type        = string
  sensitive   = true
  default     = "~/.ssh/id_rsa.pub"
  validation {
    condition     = length(regexall(".pub", var.public_key_file)) > 0
    error_message = "Public key is empty string or contains invalid characters."
  }
}

variable worker_volume_size {
  description = "Size of the volumes attached to the worker nodes in GB."
  type        = number
  default     = "20"
  validation {
    condition     = 10 <= var.worker_volume_size
    error_message = "Minimum volume size is 10 GB."
  }
}


variable "labels" {
  description = "Labels for all resources."
  type        = map(string)
  default     = {
    Project     = "k8s",
    managed_by  = "terraform"
  }
}