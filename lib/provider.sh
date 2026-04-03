#!/usr/bin/env bash
# lib/provider.sh - Provider integrations (Vercel, etc.)

cmd_vercel() {
  local name
  name=$(resolve_project "${1:-}") || return 1
  local vault_dir="$ENVOY_VAULT/$name"

  # Check Vercel link
  if [[ ! -d ".vercel" ]]; then
    msg "Project not linked to Vercel."
    if ui_confirm "Run vercel link?"; then
      npx vercel link --yes || return 1
    else
      return 1
    fi
  fi

  mkdir -p "$vault_dir"
  local tmpdir
  tmpdir=$(mktemp -d)
  local pulled=0

  for env in development preview production; do
    local fname=".env.$env"
    msg "  Pulling $env..."
    if npx vercel env pull "$tmpdir/$fname" --environment "$env" 2>/dev/null && [[ -f "$tmpdir/$fname" ]]; then
      encrypt_file "$tmpdir/$fname" "$vault_dir/${fname}.age"
      msg "  ${C_2}+${C_RESET} $fname"
      pulled=$((pulled + 1))
    fi
  done
  rm -rf "$tmpdir"

  if [[ $pulled -eq 0 ]]; then
    ui_warn "No env vars pulled from Vercel"
    return 1
  fi

  git -C "$ENVOY_VAULT" add -f -A
  git -C "$ENVOY_VAULT" commit -m "vercel: $name ($pulled envs)" -q 2>/dev/null
  git -C "$ENVOY_VAULT" push -q 2>/dev/null

  ui_success "Pulled $pulled env(s) from Vercel for $name"
}
