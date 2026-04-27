You are completely right, and your `git status` caught the discrepancy perfectly. 

The reason `perf.data` was not showing up for Docker and Kubernetes is because my previous list included `perf stat` (which generates the `perf_stat.txt` file), but I omitted `perf record` (the command that generates the binary `perf.data` file for flamegraphs/call graphs). Your host had a `perf.data` file left over from when you ran it manually earlier in our troubleshooting, which is why it showed up as "modified" in `git status` instead of "untracked".

To ensure strict 1-to-1 consistency across all environments, I have injected `perf record` into **all** profiling blocks. Every single environment will now consistently generate exactly 5 files: `perf_stat.txt`, `perf.data`, `strace.txt`, `bpftrace.txt`, and the official benchmark `.txt`.

Here is the finalized, 100% complete, copy-pasteable list. Run Phase 1, wait for it to finish, and then run Phase 2.

---

### 1. Metric: `lat_syscall null`

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_syscall_null
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_null/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 null
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_syscall_null/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 null
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall null 2>&1 | sudo tee ./results/host/lat_syscall_null/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 100000 null > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_syscall | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_getppid /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_getppid /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_null/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_syscall_null
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 null > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_null/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_syscall_null/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_null/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_getppid /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_getppid /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_null/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_syscall_null
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 null > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_null/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_syscall_null/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_syscall_null/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_getppid /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_getppid /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_syscall_null/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 50 null -o results/host/lat_syscall_null/lat_syscall_null.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 50 null -o results/docker/lat_syscall_null/lat_syscall_null.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 50 null -o results/k8s/lat_syscall_null/lat_syscall_null.txt
```

---

### 2. Metric: `lat_syscall read`

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_syscall_read
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_read/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 read
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_syscall_read/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 read
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall read 2>&1 | sudo tee ./results/host/lat_syscall_read/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 100000 read > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_syscall | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_read /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_read/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_syscall_read
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 read > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_read/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_syscall_read/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_read/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_read /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_read/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_syscall_read
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 read > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_read/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_syscall_read/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_syscall_read/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_read /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_syscall_read/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 50 read -o results/host/lat_syscall_read/lat_syscall_read.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 50 read -o results/docker/lat_syscall_read/lat_syscall_read.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 50 read -o results/k8s/lat_syscall_read/lat_syscall_read.txt
```

---

### 3. Metric: `lat_syscall write`

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_syscall_write
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_write/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 write
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_syscall_write/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 write
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall write 2>&1 | sudo tee ./results/host/lat_syscall_write/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 100000 write > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_syscall | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_write /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_write /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_write/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_syscall_write
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 write > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_write/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_syscall_write/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_write/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_write /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_write /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_write/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_syscall_write
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 write > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_write/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_syscall_write/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_syscall_write/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_write /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_write /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_syscall_write/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 50 write -o results/host/lat_syscall_write/lat_syscall_write.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 50 write -o results/docker/lat_syscall_write/lat_syscall_write.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 50 write -o results/k8s/lat_syscall_write/lat_syscall_write.txt
```

---

### 4. Metric: `lat_ctx`

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_ctx
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_ctx/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_ctx -P 1 -W 5 -N 1000 -s 32 2
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_ctx/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_ctx -P 1 -W 5 -N 1000 -s 32 2
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_ctx -s 32 2 2>&1 | sudo tee ./results/host/lat_ctx/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_ctx -P 1 -W 5 -N 10000000 -s 32 2 -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for Host PID..."
PID=""
for i in {1..20}; do
    PID=$(pgrep -x lat_ctx | tail -n 1)
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -n "$PID" ]; then
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/host/lat_ctx/bpftrace.txt
fi
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_ctx
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_ctx -P 1 -W 5 -N 10000000 -s 32 2 -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for Container PID..."
PID=""
for i in {1..20}; do
    PID=$(pgrep -x lat_ctx | tail -n 1)
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -z "$PID" ]; then
    echo "[ERROR] Could not catch process."
else
    sudo perf stat -p $PID -o ./results/docker/lat_ctx/perf_stat.txt -- sleep 5
    sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_ctx/perf.data -- sleep 5
    sudo timeout 5s strace -c -f -p $PID 2>&1 | sudo tee ./results/docker/lat_ctx/strace.txt
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/docker/lat_ctx/bpftrace.txt
fi
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Docker production**
```bash
mkdir -p results/docker/lat_ctx_prod
echo "[INFO] Launching Production Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf_production.sh lat_ctx -P 1 -W 5 -N 10000000 -s 32 2 -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for Container PID..."
PID=""
for i in {1..20}; do
    PID=$(pgrep -n -x lat_ctx)
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -z "$PID" ]; then
    echo "[ERROR] Could not catch process."
else
    sudo perf stat -p $PID -o ./results/docker/lat_ctx_prod/perf_stat.txt -- sleep 5
    sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_ctx_prod/perf.data -- sleep 5
    sudo timeout 5s strace -c -f -p $PID 2>&1 | sudo tee ./results/docker/lat_ctx_prod/strace.txt
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/docker/lat_ctx_prod/bpftrace.txt
fi
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] Production Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_ctx
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_ctx -P 1 -W 5 -N 10000000 -s 32 2 -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for K8s PID..."
PID=""
for i in {1..30}; do
    PID=$(pgrep -x lat_ctx | tail -n 1)
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -z "$PID" ]; then
    echo "[ERROR] Could not catch process."
else
    sudo perf stat -p $PID -o ./results/k8s/lat_ctx/perf_stat.txt -- sleep 5
    sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_ctx/perf.data -- sleep 5
    sudo timeout 5s strace -c -f -p $PID 2>&1 | sudo tee ./results/k8s/lat_ctx/strace.txt
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/k8s/lat_ctx/bpftrace.txt
fi
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/host/lat_ctx/lat_ctx.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/docker/lat_ctx/lat_ctx.txt
CPU_CORE=1 sudo ./docker_perf_production.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/docker/lat_ctx_prod/lat_ctx_prod.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/k8s/lat_ctx/lat_ctx.txt
```

---

### 5. Metric: `lat_proc`

#### Phase 1: Profiling
**Warmup sudo credentials**
```bash
sudo -v
```

**Host:**
```bash
mkdir -p results/host/lat_proc
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_proc/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_proc -P 1 -W 5 -N 1000 fork
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_proc/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_proc -P 1 -W 5 -N 1000 fork
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_proc fork 2>&1 | sudo tee ./results/host/lat_proc/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_proc -P 1 -W 5 -N 100000 fork > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_proc | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_clone /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_proc/bpftrace.txt
sudo pkill -9 -x lat_proc 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_proc
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_proc -P 1 -W 5 -N 10000000 fork -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for Container PID..."
PID=""
for i in {1..20}; do
    PID=$(pgrep -n -x lat_proc)
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -z "$PID" ]; then
    echo "[ERROR] Could not catch process."
else
    sudo perf stat -p $PID -o ./results/docker/lat_proc/perf_stat.txt -- sleep 5
    sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_proc/perf.data -- sleep 5
    sudo timeout 5s strace -c -f -p $PID 2>&1 | sudo tee ./results/docker/lat_proc/strace.txt
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_clone { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/docker/lat_proc/bpftrace.txt
fi
sudo pkill -9 -x lat_proc 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_proc
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_proc -P 1 -W 5 -N 10000000 fork -o /dev/null > /dev/null 2>&1 &

echo "[INFO] Hunting for K8s PID..."
PID=""
for i in {1..30}; do
    PID=$(pgrep -n -x lat_proc) 
    if [ -n "$PID" ]; then echo "[INFO] Found PID: $PID"; break; fi
    sleep 1
done

if [ -z "$PID" ]; then
    echo "[ERROR] Could not catch process."
else
    sudo perf stat -p $PID -o ./results/k8s/lat_proc/perf_stat.txt -- sleep 5
    sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_proc/perf.data -- sleep 5
    sudo timeout 5s strace -c -f -p $PID 2>&1 | sudo tee ./results/k8s/lat_proc/strace.txt
    sudo timeout 10s bpftrace -e 'tracepoint:syscalls:sys_enter_clone { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat[comm] = hist(nsecs - @start[tid]); delete(@start[tid]); }' | sudo tee ./results/k8s/lat_proc/bpftrace.txt
fi
sudo pkill -9 -x lat_proc 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/host/lat_proc/lat_proc.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/docker/lat_proc/lat_proc.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/k8s/lat_proc/lat_proc.txt
```

#### Cleanup Commands to nuke any stuck zombie processes or lingering background jobs
```bash
ps aux | grep lat_proc
sudo pkill -9 -f host_perf.sh
sudo pkill -9 -f docker_perf.sh
sudo pkill -9 -f k8s_perf.sh
kubectl delete pods --all --force --grace-period=0
```

---

### 6. Metric: `lat_pagefault`

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_pagefault
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_pagefault/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_pagefault -P 1 -W 5 -N 1000 /tmp/test
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_pagefault/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_pagefault -P 1 -W 5 -N 1000 /tmp/test
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_pagefault /tmp/test 2>&1 | sudo tee ./results/host/lat_pagefault/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_pagefault -P 1 -W 5 -N 100000 /tmp/test > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_pagefault | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_mmap /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_mmap /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_pagefault/bpftrace.txt
sudo pkill -9 -x lat_pagefault 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_pagefault
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_pagefault -P 1 -W 5 -N 100000 /tmp/test > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_pagefault | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_pagefault/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_pagefault/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_pagefault/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_mmap /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_mmap /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_pagefault/bpftrace.txt
sudo pkill -9 -x lat_pagefault 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_pagefault
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_pagefault -P 1 -W 5 -N 100000 /tmp/test > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_pagefault | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_pagefault/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_pagefault/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_pagefault/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_mmap /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_mmap /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_pagefault/bpftrace.txt
sudo pkill -9 -x lat_pagefault 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_pagefault -P 1 -W 5 -N 50 /tmp/test -o results/host/lat_pagefault/lat_pagefault.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_pagefault -P 1 -W 5 -N 50 /tmp/test -o results/docker/lat_pagefault/lat_pagefault.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_pagefault -P 1 -W 5 -N 50 /tmp/test -o results/k8s/lat_pagefault/lat_pagefault.txt
```

---

### 7. Metric: `lat_tcp`

*(Run setup once before starting:)*
```bash
sudo pkill -9 -x lat_tcp 2>/dev/null || true
sudo ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_tcp -s &
sleep 2
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host IP: $HOST_IP"
```

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_tcp
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_tcp/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_tcp -P 1 -W 5 -N 1000 localhost
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_tcp/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_tcp -P 1 -W 5 -N 1000 localhost
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_tcp localhost 2>&1 | sudo tee ./results/host/lat_tcp/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_tcp -P 1 -W 5 -N 100000 localhost > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_tcp | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_tcp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_tcp
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_tcp -P 1 -W 5 -N 100000 $HOST_IP > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_tcp | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_tcp/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_tcp/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_tcp/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_tcp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_tcp
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_tcp -P 1 -W 5 -N 100000 $HOST_IP > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_tcp | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_tcp/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_tcp/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_tcp/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_tcp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_tcp -P 1 -W 5 -N 50 localhost -o results/host/lat_tcp/lat_tcp.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_tcp -P 1 -W 5 -N 50 $HOST_IP -o results/docker/lat_tcp/lat_tcp.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_tcp -P 1 -W 5 -N 50 $HOST_IP -o results/k8s/lat_tcp/lat_tcp.txt
```

---

### 8. Metric: `lat_udp`

*(Run setup once before starting if not already running:)*
```bash
sudo pkill -9 -x lat_udp 2>/dev/null || true
sudo ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_udp -s &
sleep 2
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host IP: $HOST_IP"
```

#### Phase 1: Profiling
**Host:**
```bash
mkdir -p results/host/lat_udp
echo "[INFO] Running perf stat, perf record, and strace..."
sudo taskset -c 1 perf stat -o ./results/host/lat_udp/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_udp -P 1 -W 5 -N 1000 localhost
sudo taskset -c 1 perf record -F 999 -g -o ./results/host/lat_udp/perf.data ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_udp -P 1 -W 5 -N 1000 localhost
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_udp localhost 2>&1 | sudo tee ./results/host/lat_udp/strace.txt

echo "[INFO] Launching background process for bpftrace..."
CPU_CORE=1 sudo ./host_perf.sh lat_udp -P 1 -W 5 -N 100000 localhost > /dev/null 2>&1 &
sleep 2
PID=$(pgrep -x lat_udp | tail -n 1)
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_udp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] Host profiling complete."
```

**Docker:**
```bash
mkdir -p results/docker/lat_udp
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_udp -P 1 -W 5 -N 100000 $HOST_IP > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_udp | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_udp/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/docker/lat_udp/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_udp/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_udp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes:**
```bash
mkdir -p results/k8s/lat_udp
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_udp -P 1 -W 5 -N 100000 $HOST_IP > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_udp | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_udp/perf_stat.txt -- sleep 5
sudo perf record -F 999 -g -p $PID -o ./results/k8s/lat_udp/perf.data -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_udp/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_recvfrom /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_recvfrom /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_udp/bpftrace.txt
sudo kill -9 $PID 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_udp -P 1 -W 5 -N 50 localhost -o results/host/lat_udp/lat_udp.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_udp -P 1 -W 5 -N 50 $HOST_IP -o results/docker/lat_udp/lat_udp.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_udp -P 1 -W 5 -N 50 $HOST_IP -o results/k8s/lat_udp/lat_udp.txt
```
