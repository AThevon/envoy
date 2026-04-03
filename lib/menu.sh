#!/usr/bin/env bash
# lib/menu.sh - Interactive fzf menus with preview panels

cmd_interactive() {
  local project
  project=$(detect_project)

  if [[ -n "$project" ]]; then
    _menu_project "$project"
  else
    _menu_global
  fi
}

_build_header() {
  local subtitle="${1:-}"
  local header=""
  header+="${C_1} ▄▄▄▄▄▄▄${C_2} ▄▄▄    ▄▄▄${C_3} ▄▄▄▄  ▄▄▄▄${C_4}   ▄▄▄▄▄${C_5}   ▄▄▄   ▄▄▄${C_RESET}"$'\n'
  header+="${C_1}███▀▀▀▀▀${C_2} ████▄  ███${C_3} ▀███  ███▀${C_4} ▄███████▄${C_5} ███   ███${C_RESET}"$'\n'
  header+="${C_1}███▄▄   ${C_2} ███▀██▄███${C_3}  ███  ███${C_4}  ███   ███${C_5} ▀███▄███▀${C_RESET}"$'\n'
  header+="${C_1}███     ${C_2} ███  ▀████${C_3}  ███▄▄███${C_4}  ███▄▄▄███${C_5}   ▀███▀${C_RESET}"$'\n'
  header+="${C_1}▀███████${C_2} ███    ███${C_3}   ▀████▀${C_4}    ▀█████▀${C_5}     ███${C_RESET}"$'\n'
  if [[ -n "$subtitle" ]]; then
    header+="${C_DIM}${subtitle}${C_RESET}"
  fi
  echo "$header"
}

_preview_cmd() {
  # Generates a preview script for fzf that shows description based on icon
  cat <<'PREVIEW_SCRIPT'
    line={}
    desc=$(echo "$line" | sed 's/^[^ ]* //' | cut -d'|' -f1)
    detail=$(echo "$line" | cut -d'|' -f2)
    printf "\033[1m%s\033[0m\n\n%s\n" "$desc" "$detail"
PREVIEW_SCRIPT
}

_menu_project() {
  local name="$1"
  local vault_status="not in vault"
  local file_count=0
  if [[ -d "$ENVOY_VAULT/$name" ]]; then
    file_count=$(find_age_files "$ENVOY_VAULT/$name" | wc -l)
    vault_status="$file_count file(s) in vault"
  fi

  local header
  header=$(_build_header "  ${C_2}${name}${C_RESET}  ${C_DIM}${vault_status}${C_RESET}")

  local actions
  actions=$(cat <<EOF
 Push all|Encrypt local .env files and pull Vercel envs (if detected). Saves everything to the vault.|push
 Push local|Encrypt only local .env files (.env, .env.local, etc.) and save to the vault.|push-local
 Push Vercel|Pull development, preview and production env vars from Vercel, encrypt and save.|push-vercel
 Pull|Decrypt .env files from the vault and restore them into your project.|pull
 Diff|Line-by-line comparison between your local .env files and what's stored in the vault.|diff
── Global ─────────────────────|──────|---
 Browse vault|Browse all projects stored in the vault and manage them.|list
 Clean|Select a project to permanently remove from the vault.|clean
 Config|View and edit vault path, key path, projects directory and repo.|config
 Rotate key|Generate a new age key, re-encrypt all vault files, and display the key to save.|rotate
EOF
)

  local selected
  selected=$(echo "$actions" | \
    fzf --height=80% \
        --layout=reverse \
        --border \
        --ansi \
        --no-sort \
        --header="$header" \
        --footer=" Enter select" \
        --delimiter='|' \
        --with-nth=1 \
        --preview="
          line={};
          desc=\$(echo \"\$line\" | cut -d'|' -f1 | sed 's/^[^ ]* //');
          detail=\$(echo \"\$line\" | cut -d'|' -f2);
          printf '\033[1m%s\033[0m\n\n%s\n' \"\$desc\" \"\$detail\"
        " \
        --preview-window=right:45%:wrap)

  [[ -z "$selected" ]] && return 0

  local cmd
  cmd=$(echo "$selected" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  case "$cmd" in
    push)         cmd_push "$name" ;;
    push-local)   cmd_push_local "$name" ;;
    push-vercel)  cmd_push_vercel "$name" ;;
    pull)         cmd_pull "$name" ;;
    diff)         cmd_diff "$name" ;;
    list)         _menu_list ;;
    clean)        cmd_clean ;;
    config)       cmd_config ;;
    rotate)       cmd_rotate ;;
  esac
}

_menu_global() {
  local header
  header=$(_build_header "  ${C_DIM}encrypted .env vault${C_RESET}")

  local actions
  actions=$(cat <<EOF
 Browse vault|Browse all projects stored in the vault and manage them.|list
 Clean|Select a project to permanently remove from the vault.|clean
 Config|View and edit vault path, key path, projects directory and repo.|config
 Rotate key|Generate a new age key, re-encrypt all vault files, and display the key to save.|rotate
EOF
)

  local selected
  selected=$(echo "$actions" | \
    fzf --height=60% \
        --layout=reverse \
        --border \
        --ansi \
        --no-sort \
        --header="$header" \
        --footer=" Enter select" \
        --delimiter='|' \
        --with-nth=1 \
        --preview="
          line={};
          desc=\$(echo \"\$line\" | cut -d'|' -f1 | sed 's/^[^ ]* //');
          detail=\$(echo \"\$line\" | cut -d'|' -f2);
          printf '\033[1m%s\033[0m\n\n%s\n' \"\$desc\" \"\$detail\"
        " \
        --preview-window=right:45%:wrap)

  [[ -z "$selected" ]] && return 0

  local cmd
  cmd=$(echo "$selected" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  case "$cmd" in
    list)    _menu_list ;;
    clean)   cmd_clean ;;
    config)  cmd_config ;;
    rotate)  cmd_rotate ;;
  esac
}

_menu_list() {
  local entries=()
  for dir in "$ENVOY_VAULT"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name=$(basename "$dir")
    [[ "$name" == ".git" ]] && continue
    local files
    files=$(find_age_files "$dir" | xargs -I{} basename {} .age 2>/dev/null | tr '\n' ' ')
    local count
    count=$(find_age_files "$dir" | wc -l)
    entries+=(" ${name}  ${C_DIM}${count} file(s)${C_RESET}|${files}")
  done

  if [[ ${#entries[@]} -eq 0 ]]; then
    ui_warn "Vault is empty"
    return 0
  fi

  local header
  header=$(_build_header "  ${C_DIM}select a project${C_RESET}")

  local selected
  selected=$(printf '%s\n' "${entries[@]}" | \
    fzf --height=60% \
        --layout=reverse \
        --border \
        --ansi \
        --no-sort \
        --header="$header" \
        --footer=" Enter select" \
        --delimiter='|' \
        --with-nth=1 \
        --preview='
          files=$(echo {} | cut -d"|" -f2);
          printf "\033[1mEncrypted files\033[0m\n\n";
          for f in $files; do
            printf "  \033[38;2;52;211;153m\033[0m %s\n" "$f";
          done
        ' \
        --preview-window=right:45%:wrap)

  [[ -z "$selected" ]] && return 0

  local name
  name=$(echo "$selected" | sed 's/^ [^ ]* //' | awk '{print $1}')

  _menu_vault_project "$name"
}

_menu_vault_project() {
  local name="$1"
  local file_count
  file_count=$(find_age_files "$ENVOY_VAULT/$name" | wc -l)
  local files
  files=$(find_age_files "$ENVOY_VAULT/$name" | xargs -I{} basename {} .age 2>/dev/null | tr '\n' ' ')

  local header
  header=$(_build_header "  ${C_2}${name}${C_RESET}  ${C_DIM}${file_count} file(s)${C_RESET}")

  local actions
  actions=$(cat <<EOF
 Pull|Decrypt and copy .env files into ~/projects/${name}|pull
 Diff|Line-by-line comparison between local and vault versions|diff
 Remove|Permanently delete ${name} from the vault|clean
EOF
)

  local selected
  selected=$(echo "$actions" | \
    fzf --height=50% \
        --layout=reverse \
        --border \
        --ansi \
        --no-sort \
        --header="$header" \
        --footer=" Enter select" \
        --delimiter='|' \
        --with-nth=1 \
        --preview="
          line={};
          desc=\$(echo \"\$line\" | cut -d'|' -f1 | sed 's/^[^ ]* //');
          detail=\$(echo \"\$line\" | cut -d'|' -f2);
          printf '\033[1m%s\033[0m\n\n%s\n' \"\$desc\" \"\$detail\";
          printf '\n\033[38;2;52;211;153mFiles:\033[0m\n';
          for f in ${files}; do
            printf '  %s\n' \"\$f\";
          done
        " \
        --preview-window=right:45%:wrap)

  [[ -z "$selected" ]] && return 0

  local cmd
  cmd=$(echo "$selected" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  case "$cmd" in
    pull) cmd_pull "$name" ;;
    diff) cmd_diff "$name" ;;
    clean)
      if ui_confirm "Remove $name from the vault?"; then
        rm -rf "$ENVOY_VAULT/$name"
        git -C "$ENVOY_VAULT" add -A
        git -C "$ENVOY_VAULT" commit -m "clean: remove $name" -q 2>/dev/null
        git -C "$ENVOY_VAULT" push -q 2>/dev/null
        ui_success "Removed $name from vault"
      fi
      ;;
  esac
}
