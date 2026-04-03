#!/usr/bin/env bash
# lib/menu.sh - Interactive fzf menus

cmd_interactive() {
  local project
  project=$(detect_project)

  if [[ -n "$project" ]]; then
    _menu_project "$project"
  else
    _menu_global
  fi
}

_menu_project() {
  local name="$1"
  local vault_status=""
  if [[ -d "$ENVOY_VAULT/$name" ]]; then
    vault_status=" ${C_DIM}(in vault)${C_RESET}"
  else
    vault_status=" ${C_DIM}(not in vault)${C_RESET}"
  fi

  ui_header
  msg ""
  msg "  Project: ${C_BOLD}$name${C_RESET}$vault_status"
  msg ""

  local actions=(
    "push     Encrypt and save .env files"
    "pull     Restore .env files from vault"
    "diff     Compare local vs vault"
    "vercel   Pull from Vercel"
    "---"
    "list     All projects in vault"
    "clean    Remove a project from vault"
    "config   View and edit settings"
    "rotate   Generate new key"
  )

  local selected
  selected=$(printf '%s\n' "${actions[@]}" | gum filter --prompt="ev > " --height=12) || return 0

  local cmd
  cmd=$(echo "$selected" | awk '{print $1}')

  case "$cmd" in
    push)    cmd_push "$name" ;;
    pull)    cmd_pull "$name" ;;
    diff)    cmd_diff "$name" ;;
    vercel)  cmd_vercel "$name" ;;
    list)    cmd_list ;;
    clean)   cmd_clean ;;
    config)  cmd_config ;;
    rotate)  cmd_rotate ;;
    ---) return 0 ;;
  esac
}

_menu_global() {
  ui_header
  msg ""

  local actions=(
    "list     All projects in vault"
    "clean    Remove a project from vault"
    "config   View and edit settings"
    "rotate   Generate new key"
  )

  local selected
  selected=$(printf '%s\n' "${actions[@]}" | gum filter --prompt="ev > " --height=8) || return 0

  local cmd
  cmd=$(echo "$selected" | awk '{print $1}')

  case "$cmd" in
    list)    cmd_list ;;
    clean)   cmd_clean ;;
    config)  cmd_config ;;
    rotate)  cmd_rotate ;;
  esac
}
