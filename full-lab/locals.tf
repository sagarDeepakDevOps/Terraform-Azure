locals {
  # Built from a variable, not a resource, so the backend pool keys are known at plan time.
  web_vm_names = [for name, vm in var.vms : name if vm.role == "web"]
}
