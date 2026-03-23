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
shift   # remove benchmark name, keep remaining args

# ==============================
# PATH SETUP
# ==============================

LM_DIR="./lmbench-3.0-a9/bin/x86_64-linux-gnu"
BENCH="$LM_DIR/$BENCH_NAME"

if [ ! -x "$BENCH" ]; then
    echo "[ERROR] Benchmark binary not found: $BENCH"
    exit 1
fi

ARGS="$@"

# ==============================
# CONFIGURATION
# ==============================

OUTPUT_DIR="./results/host"
RUNS=10
CPU_CORE=${CPU_CORE:-1}

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="$OUTPUT_DIR/${BENCH_NAME}_${TIMESTAMP}.txt"

mkdir -p "$OUTPUT_DIR"

echo "[INFO] Benchmark: $BENCH_NAME"
echo "[INFO] Args: $ARGS"
echo "[INFO] Output: $OUT_FILE"

# ==============================
# SYSTEM STABILIZATION
# ==============================

echo "[INFO] Setting CPU governor..."
sudo cpupower frequency-set -g performance > /dev/null 2>&1 || true

echo "[INFO] Disabling Turbo Boost (if supported)..."
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 || true

echo "[INFO] Pinning to CPU core $CPU_CORE"

# ==============================
# SYSTEM INFO LOGGING
# ==============================

{
echo "===== SYSTEM INFO ====="
date
uname -a
lscpu
echo "======================="
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
    taskset -c $CPU_CORE $BENCH $ARGS 2>&1 | tee -a "$OUT_FILE"
    echo "" >> "$OUT_FILE"
done

# ==============================
# DONE
# ==============================
echo "[INFO] Completed $BENCH_NAME"
