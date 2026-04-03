#!/usr/bin/env bash
# lib/crypto.sh - Age encryption/decryption

# Derive public key from private key
get_public_key() {
  age-keygen -y "$ENVOY_KEY" 2>/dev/null
}

encrypt_file() {
  local src="$1" dest="$2"
  local pub
  pub=$(get_public_key) || { ui_error "Cannot read key at $ENVOY_KEY"; return 1; }
  age -r "$pub" -o "$dest" "$src"
}

decrypt_file() {
  local src="$1" dest="$2"
  age -d -i "$ENVOY_KEY" -o "$dest" "$src"
}

# Find .env files in a directory (excludes .example and .age)
find_env_files() {
  local dir="$1"
  find "$dir" -maxdepth 1 -name ".env*" -type f \
    ! -name "*.example" \
    ! -name "*.age" \
    2>/dev/null | sort
}

# Find .age files in a directory
find_age_files() {
  local dir="$1"
  find "$dir" -maxdepth 1 -name "*.age" -type f 2>/dev/null | sort
}

cmd_rotate() {
  if ! ui_confirm "Generate new key and re-encrypt all vault files?"; then
    return 0
  fi

  # 1. Decrypt everything with old key
  local tmpdir
  tmpdir=$(mktemp -d)
  msg "Decrypting vault with current key..."

  local count=0
  while IFS= read -r f; do
    local rel="${f#$ENVOY_VAULT/}"
    local dest="$tmpdir/${rel%.age}"
    mkdir -p "$(dirname "$dest")"
    decrypt_file "$f" "$dest" || { ui_error "Failed to decrypt: $f"; rm -rf "$tmpdir"; return 1; }
    count=$((count + 1))
  done < <(find "$ENVOY_VAULT" -name "*.age" -type f ! -path "*/.git/*")

  if [[ $count -eq 0 ]]; then
    ui_warn "No encrypted files found in vault"
    rm -rf "$tmpdir"
    return 0
  fi

  # 2. Generate new key
  msg "Generating new key..."
  age-keygen -o "$ENVOY_KEY" 2>&1 >&2
  chmod 600 "$ENVOY_KEY"

  # 3. Re-encrypt with new key
  msg "Re-encrypting $count files..."
  while IFS= read -r f; do
    local rel="${f#$tmpdir/}"
    local dest="$ENVOY_VAULT/${rel}.age"
    mkdir -p "$(dirname "$dest")"
    encrypt_file "$f" "$dest"
  done < <(find "$tmpdir" -name ".env*" -type f)
  rm -rf "$tmpdir"

  # 4. Commit + push
  git -C "$ENVOY_VAULT" add -f -A
  git -C "$ENVOY_VAULT" commit -m "rotate: re-encrypt with new key" -q 2>/dev/null
  git -C "$ENVOY_VAULT" push -q 2>/dev/null

  msg ""
  ui_success "Key rotated, $count files re-encrypted"
  msg ""
  msg "${C_BOLD}IMPORTANT:${C_RESET} Save the new key in your password manager:"
  msg ""
  cat "$ENVOY_KEY" >&2
}
