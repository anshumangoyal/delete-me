#!/usr/bin/env bash
set -euofab pipefail

# Patch a Running Service
kubectl patch svc kube-prometheus-stack-prometheus --type='json' \
  --patch '[{"op":"replace", "path":"/spec/type", "value":"NodePort"}]' \
  --namespace=monitoring
