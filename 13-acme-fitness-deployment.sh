#!/bin/bash

acme_fitness_web=acme-fitness-web
acme_fitness_catalog=acme-fitness-catalog

rm -rf acme-fitness-demo

git clone https://github.com/nycpivot/acme-fitness-demo.git


#WEB FRONTEND
kubectl config use-context $acme_fitness_web

kubectl apply -f acme-fitness-demo/istio-manifests/gateway.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/secrets.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/acme_fitness_cluster1.yaml

watch kubectl get pods

#CATALOG SERVICE
kubectl config use-context $acme_fitness_catalog

kubectl apply -f acme-fitness-demo/istio-manifests/gateway.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/secrets.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/acme_fitness_cluster2.yaml

watch kubectl get 

#GET INGRESS LB TO WEB
kubectl config use-context $acme_fitness_web

kubectl get services -n istio-system | grep LoadBalancer
