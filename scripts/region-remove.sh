#!/usr/bin/env bash
set -eou pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <region>"
  exit 1
fi

region="$1"

# Remove deploy key from the repository.
set +x
key_id=$(gh repo deploy-key list | grep -E "\b$region\b" | awk '{print $1}')
[ -n "$key_id" ] && gh repo deploy-key delete "$key_id"

# Clean up the region configuration.
rm -rf "configs/regions/$region"
