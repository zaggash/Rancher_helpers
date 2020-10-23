#!/usr/bin/env bash
PROJECT_TEST="$1"
NUM_DEPLOYMENTS="$2"

if [[ $# -lt 2 ]]
then
  echo "[Error] Migging Parameters !"
  exit 10
fi

addWorkload() {
  local namespace="$1"
  local deployment_suffix="$2"
  kubectl -n "$namespace" apply -f - <<EOF
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment-$deployment_suffix
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF
}

rancher project create "$PROJECT_TEST"
rancher context switch "$PROJECT_TEST"
for int in {1..200}
do
  NS="testns-$int"
  echo "Creating $NS..."
  rancher namespaces create "$NS"
  echo "* ns created."
  for ((wl=1; wl<=$NUM_DEPLOYMENTS; wl++))
  do
    echo "Adding workload $wl on $NS..."
    addWorkload "$NS" "$wl"
    echo "* workload "$wl" created."
  done
  echo "* done *"
done

