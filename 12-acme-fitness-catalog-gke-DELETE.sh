#!/bin/bash

read -p "Cluster Name (acme-fitness-catalog): " cluster_name

if [[ -z $cluster_name ]]
then
    cluster_name=acme-fitness-catalog
fi

gke_region_code=us-east1
server_name=prod-2.nsxservicemesh.vmware.com

# 1. CREATE CLUSTER
echo
echo "<<< CREATING CLUSTER >>>"
echo

sleep 5

gcloud container clusters create $cluster_name --num-nodes 2 --zone ${gke_region_code}-b
gcloud container clusters get-credentials ${cluster_name} --zone ${gke_region_code}-b

prefix=gke_pa-mjames_${gke_region_code}-b

kubectl config rename-context ${prefix}_${cluster_name} ${cluster_name}
kubectl config use-context $cluster_name


# 2. APPLY TSM K8S COMPONENTS
echo
echo "<<< APPLY TSM K8S COMPONENTS >>>"
echo

sleep 5

tsm_token=$(aws secretsmanager get-secret-value --secret-id aria-workshop | jq -r .SecretString | jq -r .\"tsm-token\")
vmware_token=$(curl "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -H "authority: console.cloud.vmware.com" -H "pragma: no-cache" -H "cache-control: no-cache" -H "accept: application/json, text/plain, */*" --data-raw "refresh_token=${tsm_token}")
access_token=$(echo ${vmware_token} | jq -r .access_token)

registration_yaml=$(curl "https://${server_name}/tsm/v1alpha1/clusters/onboard-url" -H "accept: application/json" -H "csp-auth-token: ${access_token}")
registration_url=$(echo $registration_yaml | jq .url)

kubectl apply -f $registration_url


# 3. REGISTER CLUSTER
echo
echo "<<< REGISTER CLUSTER >>>"
echo

put_response=$(curl -X PUT "https://${server_name}/tsm/v1alpha1/clusters/${cluster_name}" -H "content-type: application/json" -H "accept: application/json" -H "csp-auth-token: ${access_token}" -d "{\"displayName\":\"${cluster_name}\",\"description\":\"${cluster_name}\",\"tags\":[],\"labels\":[],\"namespaceExclusions\":[],\"autoInstallServiceMesh\":true,\"enableNamespaceExclusions\":false}")

cluster_token=$(echo $put_response | jq .token | tr -d '"')

kubectl -n vmware-system-tsm create secret generic cluster-token --from-literal=token=$cluster_token

sleep 600

get_status=$(curl "https://${server_name}/tsm/v1alpha1/clusters/${cluster_name}" -H "accept: application/json" -H "csp-auth-token: ${access_token}")

echo $get_status

