export VAULT_ADDR=http://127.0.0.1:8200

.PHONY: init
init: \
	kind-create \
	eso-install \
	vault-install \
	demo-namespace \
	vault-deploy

.PHONY: clean
clean: 
	kubectl delete -f vault/clusterSecretStore.yaml && \
	kubectl delete -f vault/clusterExternalSecret.yaml && \

.PHONY: kind-create
kind-create:
	kind create cluster --name=eso-demo

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name=eso-demo

.PHONY: eso-install
eso-install:
	helm repo add external-secrets https://charts.external-secrets.io && \
	helm repo update && \
	helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace

.PHONY: eso-uninstall
eso-uninstall:
	helm uninstall external-secrets -n external-secrets

.PHONY: demo-namespace
demo-namespace:
	kubectl apply -f namespace.yaml
	
.PHONY: vault-install
vault-install:
	helm repo add hashicorp https://helm.releases.hashicorp.com && \
	helm repo update && \
	helm install vault hashicorp/vault -n vault --create-namespace

.PHONY: vault-deploy
vault-deploy: \
	vault-expose \
	vault-init \
	vault-unseal \
	vault-policy \
	vault-config \
	vault-secret

.PHONY: vault-expose
vault-expose:
	kubectl wait pods -n vault -l app.kubernetes.io/name=vault-agent-injector --for condition=Ready --timeout=90s
	kubectl port-forward svc/vault -n vault 8200:8200 &

.PHONY: vault-init
vault-init:
	vault operator init -key-shares=5 -key-threshold=3 -format=json > vault/config/vault-keys.json 

.PHONY: vault-unseal
vault-unseal: 
	vault operator unseal `jq -r '.unseal_keys_b64[0]' vault/config/vault-keys.json` && \
	vault operator unseal `jq -r '.unseal_keys_b64[1]' vault/config/vault-keys.json` && \
	vault operator unseal `jq -r '.unseal_keys_b64[2]' vault/config/vault-keys.json` && \
	vault login `jq -r '.root_token' vault/config/vault-keys.json`

.PHONY: vault-policy
vault-policy:
	vault policy write demo-policy vault/config/policy.hcl

.PHONY: vault-config
vault-config:
	vault/config/config_vault.sh

.PHONY: vault-secret
vault-secret:
	vault secrets enable -version=2 kv
	vault kv put kv/path/to/my/secret cowsay=- < vault/config/secret.txt