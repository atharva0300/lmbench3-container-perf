#!/bin/bash
set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <benchmark> [args...] [-o output_file]"
    exit 1
fi

BENCH_NAME=$1
shift

CUSTOM_OUT=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) CUSTOM_OUT="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

RUNS=25
WARMUP=5
CPU_CORE=${CPU_CORE:-1}

if [ -n "$CUSTOM_OUT" ]; then
    OUT_FILE="$CUSTOM_OUT"
    mkdir -p "$(dirname "$OUT_FILE")"
else
    OUT_FILE="./results/docker/${BENCH_NAME}.txt"
    mkdir -p "./results/docker"
fi

: > "$OUT_FILE"

{
    echo "=== System & Config Info (Docker) ==="
    uname -a
    echo "CPU_CORE Target (Docker cpuset): $CPU_CORE"
    echo "Benchmark Command: $BENCH_NAME ${ARGS[*]}"
    echo "====================================="
    echo ""
    echo "===== RAW RESULTS ====="
} >> "$OUT_FILE"

VALUES=()

for i in $(seq 1 $RUNS)
do
    OUTPUT=$(docker run --rm \
        --cpuset-cpus="$CPU_CORE" \
        --pids-limit -1 \
        --security-opt seccomp=unconfined \
        -v "$(pwd)/lmbench-3.0-a9":/lmbench \
        ubuntu:24.04 \
        bash -c "/lmbench/bin/x86_64-linux-gnu/$BENCH_NAME ${ARGS[*]}" 2>&1) || {
        echo "[ERROR] Docker execution failed. Output:" | tee -a "$OUT_FILE"
        echo "$OUTPUT" | tee -a "$OUT_FILE"
        exit 1
    }

    # ✅ UNIVERSAL EXTRACTION LOGIC
    if [[ "$BENCH_NAME" == "lat_ctx" ]]; then
        VAL=$(echo "$OUTPUT" | tail -n 1 | awk '{print $2}')
    else
        VAL=$(echo "$OUTPUT" | awk '/microseconds/ {for(j=1;j<=NF;j++) if($j ~ /^[0-9]+\.[0-9]+$/) print $j}' | head -n 1)
    fi

    echo "Run $i: $VAL" | tee -a "$OUT_FILE"

    if [[ -n "$VAL" && $i -gt $WARMUP ]]; then
        VALUES+=("$VAL")
    fi
    sleep 0.2
done

COUNT=${#VALUES[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "[ERROR] No values captured"
    exit 1
fi

SUM=0
MIN=${VALUES[0]}
MAX=${VALUES[0]}

for v in "${VALUES[@]}"; do
    SUM=$(echo "$SUM + $v" | bc -l)
    if (( $(echo "$v < $MIN" | bc -l) )); then MIN=$v; fi
    if (( $(echo "$v > $MAX" | bc -l) )); then MAX=$v; fi
done

MEAN=$(echo "$SUM / $COUNT" | bc -l)

VAR_SUM=0
for v in "${VALUES[@]}"; do
    DIFF=$(echo "$v - $MEAN" | bc -l)
    SQ=$(echo "$DIFF * $DIFF" | bc -l)
    VAR_SUM=$(echo "$VAR_SUM + $SQ" | bc -l)
done

VARIANCE=$(echo "$VAR_SUM / $COUNT" | bc -l)
STD_DEV=$(echo "sqrt($VARIANCE)" | bc -l)
VARIATION=$(echo "$MAX - $MIN" | bc -l)
COV=$(echo "($STD_DEV / $MEAN) * 100" | bc -l)

SORTED=($(printf '%s\n' "${VALUES[@]}" | sort -n))
MID=$((COUNT / 2))

if (( COUNT % 2 == 0 )); then
    MEDIAN=$(echo "(${SORTED[$MID-1]} + ${SORTED[$MID]}) / 2" | bc -l)
else
    MEDIAN=${SORTED[$MID]}
fi

{
echo ""
echo "===== STATISTICS ====="
echo "Samples: $COUNT"
echo "Mean: $MEAN"
echo "Median: $MEDIAN"
echo "Variance: $VARIANCE"
echo "Standard Deviation: $STD_DEV"
echo "Min: $MIN"
echo "Max: $MAX"
echo "Variation (Range): $VARIATION"
echo "Coefficient of Variation (%): $COV"
echo "======================"
} | tee -a "$OUT_FILE"

echo "[INFO] Completed $BENCH_NAME (Docker)"
echo "[INFO] Mean: $MEAN | Median: $MEDIAN | StdDev: $STD_DEV | COV: $COV%"
