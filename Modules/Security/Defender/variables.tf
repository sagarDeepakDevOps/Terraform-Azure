variable "plans" {
  type        = map(string)
  description = "SUBSCRIPTION-WIDE paid Defender plans and subplans. Import existing settings before managing them here."
  default     = { VirtualMachines = "P1", StorageAccounts = "DefenderForStorageV2" }
}