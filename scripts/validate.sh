#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v terraform >/dev/null 2>&1; then
  printf 'Terraform is required. See the project README.\n' >&2
  exit 1
fi

terraform -chdir="$project_root" fmt -check -recursive

if [[ $# -gt 1 ]]; then
  printf 'Usage: bash scripts/validate.sh [root|example-name|state]\n' >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  roots=("$project_root" "$project_root"/Examples/* "$project_root/Bootstrap/state")
elif [[ "$1" == "root" ]]; then
  roots=("$project_root")
elif [[ "$1" == "state" ]]; then
  roots=("$project_root/Bootstrap/state")
elif [[ "$1" =~ ^[0-9]{2}-[a-z-]+$ && -d "$project_root/Examples/$1" ]]; then
  roots=("$project_root/Examples/$1")
else
  printf 'Unknown example: %s\n' "$1" >&2
  exit 1
fi

for root in "${roots[@]}"; do
  root_label="${root#"$project_root/"}"
  if [[ "$root" == "$project_root" ]]; then
    root_label="root starter"
  fi
  printf '\nChecking %s\n' "$root_label"
  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly -no-color
  terraform -chdir="$root" validate -no-color
  terraform -chdir="$root" test -no-color
done

printf '\nAll selected Terraform roots passed. No Azure resources were created.\n'