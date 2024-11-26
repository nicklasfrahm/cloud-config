#!/usr/bin/env bash
set -eou pipefail

# Check if necessary tools are installed.
tools=(talosctl sops)
for tool in "${tools[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "error: failed to find tool: $tool"
    exit 1
  fi
done

if [ $# -lt 1 ]; then
  echo "Usage: $0 <region>"
  exit 1
fi

region="$1"
mkdir -p "configs/regions/$region"

# Generate deploy key for the region.
deploy_key_file="configs/regions/$region/flux.id_ed25519.key"
if [[ ! -f "$deploy_key_file" ]]; then
  echo "info: generating deploy key for region: $region"

  ssh-keygen -t ed25519 -f "$deploy_key_file" -C "$region" -N ""
fi
sops --encrypt "$deploy_key_file" >"${deploy_key_file/.key/.sops.key}"

# Create deploy key in the repository.
gh repo deploy-key add --title "$region" "$deploy_key_file.pub"

# Generate secrets.
talos_secret_file="configs/regions/$region/talos.secret.yaml"
if [[ ! -f "$talos_secret_file" ]]; then
  echo "info: generating talos secrets for region: $region"

  talosctl gen secrets --output-file="$talos_secret_file"
fi
sops --encrypt "$talos_secret_file" >"${talos_secret_file/secret.yaml/sops.yaml}"
