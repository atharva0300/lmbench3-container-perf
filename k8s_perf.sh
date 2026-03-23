#!/bin/bash

set -e

# ==============================
# INPUT VALIDATION
# ==============================

if [ $# -lt 1 ]; then
    echo "Usage: $0 <benchmark> [args...]"
    echo "Example:"
    echo "  $0 lat_syscall null -P 1 -W 5 -N 50"
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

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="$OUTPUT_DIR/${BENCH_NAME}_${TIMESTAMP}.txt"

POD_NAME="lmbench-pod-$TIMESTAMP"

HOST_LM_DIR="$(pwd)/lmbench-3.0-a9"
CONTAINER_LM_DIR="/lmbench/bin/x86_64-linux-gnu"

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
    volumeMounts:
    - mountPath: /lmbench
      name: lmbench-vol
  volumes:
  - name: lmbench-vol
    hostPath:
      path: $HOST_LM_DIR
      type: Directory
EOF

# ==============================
# START POD
# ==============================

echo "[INFO] Creating pod..."
kubectl apply -f pod.yaml

echo "[INFO] Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=60s

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
        $CONTAINER_LM_DIR/$BENCH_NAME $ARGS \
        2>&1 | tee -a "$OUT_FILE"

    echo "" >> "$OUT_FILE"
done

# ==============================
# CLEANUP
# ==============================

echo "[INFO] Deleting pod..."
kubectl delete pod $POD_NAME

rm -f pod.yaml

echo "[INFO] Completed $BENCH_NAME (K8s)"
