# Extra shell functions sourced by .zshrc
# Managed by ~/personal/ansible-macos

CERT_BUNDLE="$HOME/personal/ansible-macos/certs/Cloudflare_CA.pem"

# Trust Cloudflare CA in all tools — safe to run multiple times
trust_cloudflare() {
  local cert_bundle="$CERT_BUNDLE"

  if [ ! -f "$cert_bundle" ]; then
    echo "Certificate not found: $cert_bundle"
    return 1
  fi

  # macOS System Keychain
  if ! security find-certificate -a -c "Cloudflare" /Library/Keychains/System.keychain >/dev/null 2>&1; then
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert_bundle"
    echo "Added to System Keychain."
  else
    echo "Already in System Keychain. Skipping."
  fi

  # conda / miniforge
  if command -v conda >/dev/null 2>&1; then
    conda config --set ssl_verify "$cert_bundle"
    echo "Set conda ssl_verify."
  fi

  # JVM — find keytool relative to each cacerts, import if alias missing
  find "$HOME/Library/Java" "$HOME/.sdkman" /opt/homebrew/opt -name "cacerts" 2>/dev/null | while IFS= read -r cacerts; do
    keytool_bin="$(cd "$(dirname "$cacerts")/../.." 2>/dev/null && pwd)/bin/keytool"
    [ -x "$keytool_bin" ] || keytool_bin=$(command -v keytool 2>/dev/null)
    [ -z "$keytool_bin" ] && continue

    if "$keytool_bin" -list -alias "cloudflare-ca" -keystore "$cacerts" -storepass changeit >/dev/null 2>&1; then
      echo "Already trusted: $cacerts"
    else
      "$keytool_bin" -importcert -noprompt -trustcacerts \
        -alias "cloudflare-ca" \
        -file "$cert_bundle" \
        -keystore "$cacerts" \
        -storepass changeit \
        && echo "Imported: $cacerts" \
        || echo "Failed: $cacerts"
    fi
  done

  # Docker / Colima
  mkdir -p "$HOME/.docker/certs.d"
  cp "$cert_bundle" "$HOME/.docker/certs.d/ca.crt"
  echo "Copied to Docker certs."

  # Set env vars globally via launchctl so GUI apps (VS Code, Electron) pick them up
  launchctl setenv NODE_EXTRA_CA_CERTS "$cert_bundle"
  launchctl setenv REQUESTS_CA_BUNDLE "$cert_bundle"
  launchctl setenv SSL_CERT_FILE "$cert_bundle"
  launchctl setenv CURL_CA_BUNDLE "$cert_bundle"
  echo "Set CA env vars in launchctl (active until next reboot)."

  # Install LaunchAgent so vars persist across reboots
  PLIST_SRC="$HOME/personal/ansible-macos/dotfiles/launchagents/com.user.caenv.plist"
  PLIST_DEST="$HOME/Library/LaunchAgents/com.user.caenv.plist"
  if [ -f "$PLIST_SRC" ]; then
    cp "$PLIST_SRC" "$PLIST_DEST"
    launchctl load "$PLIST_DEST" 2>/dev/null || true
    echo "LaunchAgent installed: CA env vars set at every login."
  fi

  echo "Done. Run 'source ~/.zshrc' to reload env vars."
}

# Alias for convenience in interactive shells (zsh allows hyphens)
alias trust-cloudflare=trust_cloudflare
