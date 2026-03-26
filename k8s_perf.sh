#!/bin/bash

set -e

# ==============================
# HANDLE SUDO (FIX KUBECTL ISSUE)
# ==============================

if [ "$EUID" -eq 0 ]; then
    if [ -z "$SUDO_USER" ]; then
        echo "[ERROR] Cannot determine original user"
        exit 1
    fi

    export KUBECONFIG="/home/$SUDO_USER/.kube/config"
    echo "[INFO] Running as root, using kubeconfig: $KUBECONFIG"
fi

# ==============================
# CHECK KUBERNETES CLUSTER
# ==============================

if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "[ERROR] Kubernetes cluster not running"
    echo "[INFO] Try: minikube start"
    exit 1
fi

# ==============================
# INPUT VALIDATION
# ==============================

if [ $# -lt 1 ]; then
    echo "Usage: $0 <benchmark> [args...]"
    exit 1
fi

BENCH_NAME=$1
shift
ARGS="$@"

# ==============================
# CONFIGURATION
# ==============================

OUTPUT_DIR="./results/k8s"
RUNS=10
CPU_CORE=${CPU_CORE:-1}

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
OUT_FILE="$OUTPUT_DIR/${BENCH_NAME}_${TIMESTAMP}.txt"

POD_NAME="lmbench-pod-$TIMESTAMP"

HOST_LM_DIR="$(pwd)/lmbench-3.0-a9"


mkdir -p "$OUTPUT_DIR"

echo "[INFO] Benchmark: $BENCH_NAME"
echo "[INFO] Args: $ARGS"
echo "[INFO] Output: $OUT_FILE"

# ==============================
# CREATE POD YAML
# ==============================

cat <<EOF > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  restartPolicy: Never
  containers:
  - name: lmbench
    image: ubuntu:20.04
    command: ["sleep", "infinity"]
    resources:
      requests:
        cpu: "1"
      limits:
        cpu: "1"
EOF

# ==============================
# START POD
# ==============================

echo "[INFO] Creating pod..."
kubectl apply -f pod.yaml --validate=false

echo "[INFO] Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=60s

echo "[INFO] Copying lmbench into pod..."
kubectl cp "$HOST_LM_DIR" "$POD_NAME:/lmbench"

sleep 2

echo "[INFO] Detecting lmbench path inside pod..."

LM_PATH=$(kubectl exec $POD_NAME -- find /lmbench -type d -name "x86_64-linux-gnu" | head -n 1)


if [ -z "$LM_PATH" ]; then
    echo "[ERROR] Could not find lmbench binary path"
    kubectl exec $POD_NAME -- ls -R /lmbench
    exit 1
fi

echo "[INFO] Found lmbench path: $LM_PATH"

# ==============================
# SYSTEM INFO LOGGING
# ==============================

{
echo "===== SYSTEM INFO (K8s) ====="
date
kubectl get pod $POD_NAME -o wide
echo "============================"
echo ""
echo "Benchmark: $BENCH_NAME"
echo "Args: $ARGS"
echo ""
} >> "$OUT_FILE"

# ==============================
# BENCHMARK RUN
# ==============================

echo "===== RAW RESULTS =====" >> "$OUT_FILE"

for i in $(seq 1 $RUNS)
do
    echo "[INFO] Run $i"

    echo "Run $i:" | tee -a "$OUT_FILE"

    kubectl exec $POD_NAME -- \
        $LM_PATH/$BENCH_NAME $ARGS \
        2>&1 | tee -a "$OUT_FILE"

    echo "" >> "$OUT_FILE"
done

# ==============================
# CLEANUP
# ==============================

echo "[INFO] Deleting pod..."
kubectl delete pod $POD_NAME --ignore-not-found

rm -f pod.yaml

echo "[INFO] Completed $BENCH_NAME (K8s)"
