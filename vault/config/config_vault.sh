export VAULT_ADDR=http://127.0.0.1:8200

vault auth enable kubernetes 
k8s_host="$(kubectl exec vault-0 -n vault -- printenv | grep KUBERNETES_PORT_443_TCP_ADDR | cut -f 2- -d "=" | tr -d " ")" 
k8s_port="443" 
k8s_cacert="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)" 
secret_name="$(kubectl get serviceaccount vault -n vault -o jsonpath='{.secrets[0].name}')" 
tr_account_token="$(kubectl get secret ${secret_name} -n vault -o jsonpath='{.data.token}' | base64 --decode)" 
vault write auth/kubernetes/config token_reviewer_jwt="${tr_account_token}" \
	kubernetes_host="https://${k8s_host}:${k8s_port}" kubernetes_ca_cert="${k8s_cacert}" \
	disable_issuer_verification=true 
demo_secret_name="$(kubectl get serviceaccount external-secrets -n external-secrets  -o jsonpath='{.secrets[0].name}')"
demo_account_token="$(kubectl get secret ${demo_secret_name} -n external-secrets -o jsonpath='{.data.token}' | base64 --decode)" 
vault write auth/kubernetes/role/demo-role \
   	bound_service_account_names=external-secrets \
   	bound_service_account_namespaces=external-secrets \
   	policies=demo-policy \
   	ttl=24h
vault write auth/kubernetes/login role=demo-role jwt=${demo_account_token} iss=https://kubernetes.default.svc.cluster.local