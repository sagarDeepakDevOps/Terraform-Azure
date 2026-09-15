param(
    [string]$EnvironmentName = "demo"
)

$ErrorActionPreference = "Stop"

[PSCustomObject]@{
    Environment = $EnvironmentName
    TimeUtc     = [DateTime]::UtcNow.ToString("o")
    Message     = "Azure Automation runbook managed with Terraform"
} | ConvertTo-Json