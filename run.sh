#!/usr/bin/env bash
#
# Drives the numbered exercises in order: plan, apply, destroy or inspect.
# Each exercise is its own Terraform root, so this only automates the order
# and the prompting; it runs the same commands you would run by hand.
#
#   ./run.sh plan <what>       show the plan for each exercise that can be planned
#   ./run.sh apply <what>      plan each, confirm, apply, in order 1 -> 8
#   ./run.sh destroy <what>    tear down in reverse order 8 -> 1
#   ./run.sh output <what>     print outputs of the applied exercises
#   ./run.sh validate          fmt check and validate, no Azure calls
#   ./run.sh status            show which exercises are applied
#
# <what> says which exercises to act on, and is required so nothing runs by
# accident. Any of these forms, and you may combine them:
#
#   all          every exercise, in order
#   3            just exercise3
#   1-4          exercise1 through exercise4
#   exercise3    the full directory name also works
#
#   ./run.sh apply all                 build the whole lab
#   ./run.sh plan 2                    plan exercise2 only
#   ./run.sh apply 1-3                 the first three, in order
#   ./run.sh apply all --yes           skip the confirmation prompt

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Plans can contain secrets, such as the generated SSH private key, so they are
# written to a private temp directory and removed when the script exits.
PLAN_DIR="$(mktemp -d)"
trap 'rm -rf "$PLAN_DIR"' EXIT

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  BOLD=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

ASSUME_YES=false
COMMAND="${1:-}"
shift || true

ARGS=()
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=true ;;
    *) ARGS+=("$arg") ;;
  esac
done

banner() { printf '\n%s========== %s ==========%s\n' "$BOLD$BLUE" "$1" "$RESET"; }
note()   { printf '%s%s%s\n' "$YELLOW" "$1" "$RESET"; }
ok()     { printf '%s%s%s\n' "$GREEN" "$1" "$RESET"; }
fail()   { printf '%s%s%s\n' "$RED" "$1" "$RESET" >&2; }

die() { fail "$1"; exit 1; }

all_exercises() { find . -maxdepth 1 -type d -name 'exercise*' -printf '%f\n' | sort -V; }

# Turns the <what> arguments into an ordered, de-duplicated list of directories.
# Accepts all, a number, a range like 1-4, or a full exercise directory name.
targets() {
  local out=() token dir i lo hi expanded=()

  if [[ ${#ARGS[@]} -eq 0 ]]; then
    die "Say which exercises: all, a number like 3, a range like 1-4, or exercise3. See ./run.sh --help"
  fi

  for token in "${ARGS[@]}"; do
    expanded=()
    case "$token" in
      all)
        while read -r dir; do expanded+=("$dir"); done < <(all_exercises)
        ;;
      exercise[0-9]*)
        expanded=("$token")
        ;;
      [0-9]*-[0-9]*)
        lo="${token%%-*}"; hi="${token##*-}"
        [[ "$lo" -le "$hi" ]] || die "Range $token runs backwards. Write it as ${hi}-${lo}."
        for ((i = lo; i <= hi; i++)); do expanded+=("exercise$i"); done
        ;;
      [0-9]*)
        expanded=("exercise$token")
        ;;
      *)
        die "Unknown target: $token. Use all, a number like 3, a range like 1-4, or exercise3."
        ;;
    esac

    for dir in "${expanded[@]}"; do
      [[ -d "$dir" ]] || die "No such exercise: $dir"
      # Keep the first mention, drop repeats, so 1-3 2 does not plan exercise2 twice.
      [[ " ${out[*]-} " == *" $dir "* ]] || out+=("$dir")
    done
  done

  printf '%s\n' "${out[@]}"
}

require_tools() {
  command -v terraform >/dev/null || die "terraform is not installed. See the README."
  command -v az >/dev/null || die "the Azure CLI is not installed. See the README."
}

require_azure() {
  az account show >/dev/null 2>&1 || die "Not signed in to Azure. Run: az login"
  if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
    note "ARM_SUBSCRIPTION_ID was unset; using the CLI's current subscription."
  fi
  printf 'Subscription: %s\n' "$(az account show --query name -o tsv)"
}

init_if_needed() {
  local dir="$1"
  [[ -d "$dir/.terraform" ]] && return 0
  printf 'Initialising %s...\n' "$dir"
  terraform -chdir="$dir" init -input=false >/dev/null
}

# True when this exercise has resources recorded in its state.
is_applied() {
  local dir="$1"
  [[ -f "$dir/terraform.tfstate" ]] || return 1
  [[ -n "$(terraform -chdir="$dir" state list 2>/dev/null)" ]]
}

# True when every exercise ordered before this one has been applied.
prereqs_applied() {
  local target="$1" dir
  for dir in $(all_exercises); do
    [[ "$dir" == "$target" ]] && return 0
    is_applied "$dir" || return 1
  done
  return 0
}

confirm() {
  $ASSUME_YES && return 0
  local answer
  printf '%sApply this plan? [y/N] %s' "$BOLD" "$RESET"
  { read -r answer < /dev/tty; } 2>/dev/null || answer=""
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

cmd_validate() {
  require_tools
  banner "Formatting"
  if terraform fmt -check -recursive .; then ok "All files formatted."; else
    fail "Files above need: terraform fmt -recursive ."; return 1
  fi
  local failed=0
  for dir in $(all_exercises); do
    banner "Validating $dir"
    terraform -chdir="$dir" init -backend=false -input=false >/dev/null
    if terraform -chdir="$dir" validate; then :; else failed=1; fi
  done
  [[ $failed -eq 0 ]] || return 1
  ok "Every exercise is valid."
}

cmd_status() {
  require_tools
  printf '\n%-12s %-10s %s\n' "EXERCISE" "STATE" "BUILDS"
  printf -- '---------------------------------------------------------\n'
  for dir in $(all_exercises); do
    local label colour builds
    if is_applied "$dir"; then label="applied"; colour="$GREEN"; else label="not applied"; colour="$YELLOW"; fi
    # Pad the plain label first: colour escapes would otherwise count as width.
    builds="$(sed -n 's/^# Exercise [0-9]*: //p' "$dir/main.tf" | head -1)"
    builds="$(printf '%s' "${builds:-unknown}" | sed 's/^\(.\)/\U\1/; s/\.$//')"
    printf '%-12s %s%-11s%s %s\n' "$dir" "$colour" "$label" "$RESET" "$builds"
  done
  printf '\n'
}

cmd_output() {
  require_tools
  for dir in $(targets); do
    is_applied "$dir" || continue
    banner "$dir outputs"
    terraform -chdir="$dir" output
  done
}

# An exercise can only be planned once the ones before it are applied, because it
# looks their resources up by name. So plan as far as the chain allows, then list
# the rest as pending rather than printing the same lookup error eight times.
cmd_plan() {
  require_tools; require_azure
  local blocked=false rc=0
  local pending=()
  for dir in $(targets); do
    if $blocked; then pending+=("$dir"); continue; fi

    banner "Plan: $dir"
    init_if_needed "$dir"
    if terraform -chdir="$dir" plan -input=false; then
      # Nothing after an unapplied exercise can be planned: its resources do not exist yet.
      is_applied "$dir" || blocked=true
    else
      blocked=true
      fail "Plan failed for $dir."
      if prereqs_applied "$dir"; then
        rc=1
        note "Everything before it is applied, so this is a real error, not a missing prerequisite."
      else
        note "An exercise before this one has not been applied, and this one looks its resources up by name."
        note "Run ./run.sh status to see what is missing, or ./run.sh apply all to build them in order."
      fi
    fi
  done

  if [[ ${#pending[@]} -gt 0 ]]; then
    banner "Not planned yet"
    note "These look up resources that do not exist until the exercises before them are applied:"
    printf '  %s\n' "${pending[@]}"
    printf '\n'
    note "Run ./run.sh apply all to work through them in order."
  fi
  return $rc
}

cmd_apply() {
  require_tools; require_azure
  local list; list="$(targets)"
  banner "Applying in this order"
  printf '%s\n' "$list"
  for dir in $list; do
    banner "Plan: $dir"
    init_if_needed "$dir"
    local plan_file="$PLAN_DIR/$dir.tfplan"

    # -detailed-exitcode: 0 = no changes, 1 = error, 2 = changes to apply.
    set +e
    terraform -chdir="$dir" plan -input=false -detailed-exitcode -out="$plan_file"
    local code=$?
    set -e

    case $code in
      0) ok "$dir is already up to date, nothing to apply."; continue ;;
      2) : ;;
      *) die "Plan failed for $dir. Nothing was applied." ;;
    esac

    if ! confirm; then note "Skipped $dir. Later exercises may fail without it."; continue; fi

    banner "Apply: $dir"
    # Applying the saved plan guarantees you get exactly what you just reviewed.
    terraform -chdir="$dir" apply -input=false "$plan_file" || die "Apply failed for $dir."
    rm -f "$plan_file"
    ok "$dir applied."
    terraform -chdir="$dir" output
  done
  banner "Done"
  note "VMs keep booting after apply returns. Allow about a minute before the web page answers."
}

cmd_destroy() {
  require_tools; require_azure
  # Reverse order: Azure refuses to delete a resource another one still uses.
  local list; list="$(targets | tac)"
  banner "Destroying in this order"
  printf '%s\n' "$list"
  if ! $ASSUME_YES; then
    local answer
    printf '%sThis permanently deletes those resources. Type "destroy" to continue: %s' "$BOLD$RED" "$RESET"
    { read -r answer < /dev/tty; } 2>/dev/null || answer=""
    [[ "$answer" == "destroy" ]] || die "Cancelled."
  fi
  for dir in $list; do
    if ! is_applied "$dir"; then note "Skipping $dir, nothing in its state."; continue; fi
    banner "Destroy: $dir"
    init_if_needed "$dir"
    terraform -chdir="$dir" destroy -input=false -auto-approve || die "Destroy failed for $dir. Fix it before continuing, or later ones will fail too."
    ok "$dir destroyed."
  done
  banner "Done"
  note 'Confirm with: az group exists -n <prefix>-rg   (should print false)'
}

case "$COMMAND" in
  plan)     cmd_plan ;;
  apply)    cmd_apply ;;
  destroy)  cmd_destroy ;;
  output)   cmd_output ;;
  validate) cmd_validate ;;
  status)   cmd_status ;;
  ""|-h|--help|help)
    awk 'NR<3 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
    ;;
  *) die "Unknown command: $COMMAND. Run ./run.sh --help" ;;
esac
