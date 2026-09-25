output "public_key_openssh" {
  description = "Public key in OpenSSH format, for admin_ssh_key."
  value       = tls_private_key.this.public_key_openssh
}

output "private_key_path" {
  description = "Path of the written private key."
  value       = local_sensitive_file.private_key.filename
}
