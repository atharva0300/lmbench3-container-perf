#!/bin/bash

set -e

# ==============================
# INPUT VALIDATION
# ==============================

if [ $# -lt 1 ]; then
    echo "Usage: $0 <benchmark> [args...]"
    echo "Example:"
    echo "  $0 lat_syscall null -P 1 -W 5 -N 50"
    echo "  $0 bw_mem 128M rd"
    exit 1
fi

BENCH_NAME=$1
shift

ARGS="$@"

# ==============================
# CONFIGURATION
# ==============================

LM_DIR="/lmbench/bin/x86_64-linux-gnu"
HOST_LM_DIR="$(pwd)/lmbench-3.0-a9"

OUTPUT_DIR="./results/docker"
RUNS=10
CPU_CORE=${CPU_CORE:-1}

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="$OUTPUT_DIR/${BENCH_NAME}_${TIMESTAMP}.txt"

mkdir -p "$OUTPUT_DIR"

echo "[INFO] Benchmark: $BENCH_NAME"
echo "[INFO] Args: $ARGS"
echo "[INFO] Output: $OUT_FILE"

# ==============================
# SYSTEM INFO LOGGING
# ==============================

{
echo "===== SYSTEM INFO (DOCKER) ====="
date
uname -a
echo "CPU core pinned: $CPU_CORE"
echo "==============================="
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

    docker run --rm \
        --cpuset-cpus="$CPU_CORE" \
        -v "$HOST_LM_DIR":/lmbench \
        ubuntu:20.04 \
        bash -c "$LM_DIR/$BENCH_NAME $ARGS" \
        2>&1 | tee -a "$OUT_FILE"

    echo "" >> "$OUT_FILE"
done

# ==============================
# DONE
# ==============================

echo "[INFO] Completed $BENCH_NAME (Docker)"
