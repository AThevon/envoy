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
  local ev_bin="${ENVOY_BIN:-$0}"

  local header
  header="$(printf '%b' "${C_2}config${C_RESET} │ ${C_DIM}${ENVOY_RC}${C_RESET}")"

  local menu_items=(
    "vault   │ ${C_2}◈${C_RESET}  Vault path       ${C_DIM}${ENVOY_VAULT}${C_RESET}"
    "key     │ ${C_2}⚿${C_RESET}  Key path         ${C_DIM}${ENVOY_KEY}${C_RESET}"
    "projects│ ${C_2}▤${C_RESET}  Projects path    ${C_DIM}${ENVOY_PROJECTS}${C_RESET}"
    "repo    │ ${C_2}⊞${C_RESET}  GitHub repo      ${C_DIM}${ENVOY_REPO:-not set}${C_RESET}"
  )

  local tmpfile
  tmpfile="$(mktemp)"

  printf '%s\n' "${menu_items[@]}" \
  | fzf \
    --ansi \
    --no-sort \
    --height=30% \
    --layout=reverse \
    --border \
    --header "$header" \
    --preview "bash '$ev_bin' _config-preview {1}" \
    --preview-window "right:50%:wrap" \
    --delimiter "│" \
    --with-nth 2.. \
  > "$tmpfile" || { rm -f "$tmpfile"; return 0; }

  local choice
  choice="$(cat "$tmpfile")"
  rm -f "$tmpfile"

  local cmd
  cmd="$(echo "$choice" | awk -F'│' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')"

  local current=""
  local var_name=""
  case "$cmd" in
    vault)    current="$ENVOY_VAULT"; var_name="ENVOY_VAULT" ;;
    key)      current="$ENVOY_KEY"; var_name="ENVOY_KEY" ;;
    projects) current="$ENVOY_PROJECTS"; var_name="ENVOY_PROJECTS" ;;
    repo)     current="$ENVOY_REPO"; var_name="ENVOY_REPO" ;;
    *) return 0 ;;
  esac

  local new_value
  new_value=$(gum input --prompt="$var_name: " --value="$current") || return 0

  case "$cmd" in
    vault)    ENVOY_VAULT="$new_value" ;;
    key)      ENVOY_KEY="$new_value" ;;
    projects) ENVOY_PROJECTS="$new_value" ;;
    repo)     ENVOY_REPO="$new_value" ;;
  esac

  save_config
  ui_success "Config saved"
}

# Config preview - called by fzf via ev.sh dispatch
config_preview() {
  local key="$1"
  local G=$'\033[38;2;52;211;153m' R=$'\033[0m' B=$'\033[1m' D=$'\033[2m'

  case "$key" in
    vault)
      echo -e "${G}◈${R}  Vault path"
      echo ""
      echo "Path to the vault directory."
      echo "This is a git repo containing"
      echo "encrypted .env files."
      echo ""
      echo -e "${D}Default: ~/.env-vault${R}"
      ;;
    key)
      echo -e "${G}⚿${R}  Key path"
      echo ""
      echo "Path to your age private key."
      echo "Used to encrypt and decrypt"
      echo ".env files in the vault."
      echo ""
      echo -e "${D}Default: ~/.age/key.txt${R}"
      ;;
    projects)
      echo -e "${G}▤${R}  Projects path"
      echo ""
      echo "Path to your projects directory."
      echo "Used to resolve project names"
      echo "when not inside a git repo."
      echo ""
      echo -e "${D}Default: ~/projects${R}"
      ;;
    repo)
      echo -e "${G}⊞${R}  GitHub repo"
      echo ""
      echo "GitHub repo for the vault"
      echo "(user/name format)."
      echo ""
      echo "Set automatically during ev init."
      ;;
  esac
}
