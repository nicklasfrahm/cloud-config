.PHONY: seal
seal: ## Find all secrets and encrypt them while replacing the extension .secret.yaml with .sops.yaml.
	@find . -type f -name '*.secret.yaml' -exec sh -c 'sops encrypt --output=$${1%.secret.yaml}.sops.yaml $${1}' _ {} \;

.PHONY: unseal
unseal: ## Find all secrets and decrypt them while replacing the extension .sops.yaml with .secret.yaml.
	@find . -type f -name '*.sops.yaml' -exec sh -c 'sops decrypt --output=$${1%.sops.yaml}.secret.yaml $${1}' _ {} \;
