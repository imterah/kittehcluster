#!/usr/bin/env bash
kubectl -n kubernetes-dashboard create token admin-user
echo
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
