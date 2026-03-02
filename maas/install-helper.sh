
oc apply -f gateway-class.yaml

# Cluster administrator must create the namespace maas-api

oc create namespace maas-api


# Cluster administrator must deploy maas-api objects
export CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')


oc apply --server-side=true \
  -f <(oc kustomize "https://github.com/opendatahub-io/maas-billing.git/deployment/overlays/openshift?ref=main" | \
       envsubst '$CLUSTER_DOMAIN')

# Cluster administrator must adjust Audience policy

AUD="$(oc create token default --duration=10m 2>/dev/null | cut -d. -f2 | base64 -d 2>/dev/null | jq -r '.aud[0]' 2>/dev/null)"
echo $AUD

# Output:
#   https://kubernetes.default.svc

oc patch authpolicy maas-api-auth-policy -n maas-api --type=merge --patch-file <(echo "  
spec:
  rules:
    authentication:
      openshift-identities:
        kubernetesTokenReview:
          audiences:
            - $AUD
            - maas-default-gateway-sa")
