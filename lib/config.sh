#!/usr/bin/env bash
# lib/config.sh - Configuration management

ENVOY_RC="$HOME/.envoyrc"

# Defaults
ENVOY_VAULT="${ENVOY_VAULT:-$HOME/.env-vault}"
ENVOY_KEY="${ENVOY_KEY:-$HOME/.age/key.txt}"
ENVOY_PROJECTS="${ENVOY_PROJECTS:-$HOME/projects}"
ENVOY_REPO="${ENVOY_REPO:-}"

load_config() {
  if [[ -f "$ENVOY_RC" ]]; then
    source "$ENVOY_RC"
  fi
}

save_config() {
  cat > "$ENVOY_RC" <<EOF
ENVOY_VAULT="$ENVOY_VAULT"
ENVOY_KEY="$ENVOY_KEY"
ENVOY_PROJECTS="$ENVOY_PROJECTS"
ENVOY_REPO="$ENVOY_REPO"
EOF
}

cmd_config() {
  msg "${C_BOLD}Current config${C_RESET} ($ENVOY_RC)"
  msg ""
  msg "  ${C_2}ENVOY_VAULT${C_RESET}    $ENVOY_VAULT"
  msg "  ${C_2}ENVOY_KEY${C_RESET}      $ENVOY_KEY"
  msg "  ${C_2}ENVOY_PROJECTS${C_RESET} $ENVOY_PROJECTS"
  msg "  ${C_2}ENVOY_REPO${C_RESET}     $ENVOY_REPO"
  msg ""

  local choice
  choice=$(printf "vault path\nkey path\nprojects path\nrepo\nback" | gum filter --prompt="Edit > " --height=8) || return 0

  case "$choice" in
    "vault path")
      ENVOY_VAULT=$(gum input --prompt="Vault path: " --value="$ENVOY_VAULT")
      ;;
    "key path")
      ENVOY_KEY=$(gum input --prompt="Key path: " --value="$ENVOY_KEY")
      ;;
    "projects path")
      ENVOY_PROJECTS=$(gum input --prompt="Projects path: " --value="$ENVOY_PROJECTS")
      ;;
    "repo")
      ENVOY_REPO=$(gum input --prompt="GitHub repo: " --value="$ENVOY_REPO")
      ;;
    *) return 0 ;;
  esac

  save_config
  ui_success "Config saved"
}
