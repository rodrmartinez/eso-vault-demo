# External Secret Operator demo using a local instance of Hashicorp Vault

## Requirements
* [Kind](https://kind.sigs.k8s.io/)
* Helm

## Usage

### Init
Running the make init command should:

* Create a kind cluster
* Create a namespace with the required labels
* Install the External Secrets Operator
* Deploy and configure a local instance of Vault, it will be exposed on port 8200

### Sync secrets

After Vault is Up & Running, apply the `clusterExternalSecret` and `clusterSecretStore` manifests
