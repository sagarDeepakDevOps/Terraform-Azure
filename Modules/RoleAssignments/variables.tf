variable "assignments" {
  type = map(object({
    scope          = string
    role           = string
    principal_id   = string
    principal_type = optional(string, "ServicePrincipal")
  }))
  description = "Least-privilege role grants keyed by stable names. Caller needs roleAssignments/write on each scope."
}