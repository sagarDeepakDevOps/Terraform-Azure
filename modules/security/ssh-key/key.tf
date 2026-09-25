# One key pair for every VM in every spoke; RSA because Azure's admin_ssh_key expects ssh-rsa.
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Written next to the root so ssh -i works straight away; it is also stored in state in plaintext.
resource "local_sensitive_file" "private_key" {
  filename        = var.private_key_path
  content         = tls_private_key.this.private_key_pem
  file_permission = "0600"
}
