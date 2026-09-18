locals {
  # Known at plan time because it reads a variable, not a resource. A map key
  # that is only known after apply would make the backend pool unplannable.
  web_vm_names = [for name, vm in var.vms : name if vm.role == "web"]
}
