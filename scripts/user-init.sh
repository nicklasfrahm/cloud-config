#!/usr/bin/env bash
set -eou pipefail

# Check if necessary tools are installed.
tools=(age-keygen)
for tool in "${tools[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "error: failed to find tool: $tool"
    exit 1
  fi
done

# Check if user has an age keypair.
age_key="$HOME/.config/sops/age/keys.txt"
if [ -f "$age_key" ]; then
  echo "info: found age keypair: $age_key"
else
  echo "info: generating age keypair: $age_key"
  age-keygen -o "$age_key"
fi
