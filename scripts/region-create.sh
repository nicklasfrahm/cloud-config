#!/usr/bin/env bash
set -eou pipefail

region=""
region_dir=""

# tmp_dir="$(mktemp -d)"
tmp_dir="."

cleanup() {
  # Ignore errors during cleanup.
  rm -rf "$tmp_dir" || true
}

# trap cleanup EXIT SIGINT

preflight_checks() {
  # Check if necessary tools are installed.
  tools=(talosctl sops gh flux ssh-keygen)
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
  region_dir="./configs/regions/$region"

  mkdir -p "$region_dir"
}

configure_deploy_key() {
  deploy_key_file="$region_dir/flux.id_ed25519.key"
  if [[ ! -f "$deploy_key_file" ]]; then
    echo "info: generating deploy key for region: $region"

    ssh-keygen -t ed25519 -f "$deploy_key_file" -C "$region" -N ""
  fi
  if [[ ! -f "${deploy_key_file/.key/.sops.key}" ]]; then
    sops --encrypt "$deploy_key_file" >"${deploy_key_file/.key/.sops.key}"
  fi

  public_key=$(awk '{print $2}' <"$deploy_key_file.pub")
  if ! gh repo deploy-key list | grep -q "$public_key"; then
    gh repo deploy-key add --title "$region" "$deploy_key_file.pub"
  fi
}

generate_talos_secrets() {
  talos_secret_file="$region_dir/talos.secret.yaml"
  if [[ ! -f "$talos_secret_file" ]]; then
    echo "info: generating talos secrets for region: $region"

    talosctl gen secrets --output-file="$talos_secret_file"
  fi
  if [[ ! -f "${talos_secret_file/.secret.yaml/.sops.yaml}" ]]; then
    sops --encrypt "$talos_secret_file" >"${talos_secret_file/.secret.yaml/.sops.yaml}"
  fi
}

generate_talos_flux_patch() {
  flux_dir="clusters/$region/flux-system"
  flux_components="source-controller,helm-controller,kustomize-controller,notification-controller"

  export REPO_URL
  export CLUSTER

  REPO_URL="ssh://$(gh repo view --json "sshUrl" --jq ".sshUrl" | tr ":" "/")"
  CLUSTER="$region"

  mkdir -p "$flux_dir"

  # Configure flux components in configuration repository.
  envsubst <"configs/flux/kustomization.tpl.yaml" >"$flux_dir/kustomization.yaml"
  envsubst <"configs/flux/gotk-sync.tpl.yaml" >"$flux_dir/gotk-sync.yaml"
  flux install \
    --components="$flux_components" \
    --export >"$flux_dir/gotk-components.yaml"

  # Prepare flux manifests for Talos deployment.
  flux_manifest="$(cat "$flux_dir/gotk-components.yaml")"
  flux_manifest+="$(cat "$flux_dir/gotk-sync.yaml")"
  flux_manifest+="$(flux create secret git flux-system \
    --url="$REPO_URL" \
    --private-key-file="$region_dir/flux.id_ed25519.key" --export)"

  echo "$flux_manifest" >"talos.flux-system.yaml"

  ## TODO: Set up SOPS for flux.
}

main() {
  preflight_checks "$@"
  configure_deploy_key
  generate_talos_secrets
  generate_talos_flux_patch
}

main "$@"
