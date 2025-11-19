provider "aws" {
  region = var.aws_region
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = var.proxmox_api_token
  
  # Skip TLS verification for homelab (self-signed certs)
  insecure = true
  
  ssh {
    agent = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
