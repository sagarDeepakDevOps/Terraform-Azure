# One key pair for every VM this module builds; RSA because Azure's admin_ssh_key expects ssh-rsa.
resource "tls_private_key" "vms" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Writes the shared private key to the caller's directory so ssh -i works immediately; it is also held in state in plaintext.
resource "local_sensitive_file" "private_key" {
  filename        = var.private_key_path
  content         = tls_private_key.vms.private_key_pem
  file_permission = "0600"
}
