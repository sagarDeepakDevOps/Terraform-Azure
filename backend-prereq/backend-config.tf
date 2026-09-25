# Writes backend.hcl into the repository root for: terraform init -backend-config=backend.hcl
resource "local_file" "backend_config" {
  count = var.write_backend_config_file ? 1 : 0

  filename        = "${path.root}/../backend.hcl"
  content         = module.tfstate.backend_hcl
  file_permission = "0644"
}
