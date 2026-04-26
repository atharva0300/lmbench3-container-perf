To give you a flawless, copy-pasteable execution plan, I have engineered automated "Profiling Blocks" for Docker and Kubernetes. 

Because container Process IDs change randomly, these blocks will automatically launch your benchmark in the background with a massive loop count, hunt down the exact Kernel PID of the containerized process, attach `perf`, `strace`, and `bpftrace` to it, and cleanly kill the container when profiling is finished. 

Here is your complete, master list of exact commands for all 6 metrics across all 3 environments.

---

### 1. Metric: `lat_syscall null`

#### Phase 1: Profiling (Run these blocks one by one)

**Host Profiling:**
```bash
mkdir -p results/host/lat_syscall_null
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_null/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 null
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall null 2>&1 | sudo tee ./results/host/lat_syscall_null/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_getppid { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_getppid /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_null/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_syscall_null
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 null > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_null/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_null/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_getppid /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_getppid /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_null/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_syscall_null
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 null > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_null/perf_stat.txt -- sleep 5
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

**Host Profiling:**
```bash
mkdir -p results/host/lat_syscall_read
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_read/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 read
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall read 2>&1 | sudo tee ./results/host/lat_syscall_read/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_read/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_syscall_read
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 read > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_read/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_read/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_read /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_read /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_read/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_syscall_read
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 read > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_read/perf_stat.txt -- sleep 5
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

**Host Profiling:**
```bash
mkdir -p results/host/lat_syscall_write
sudo taskset -c 1 perf stat -o ./results/host/lat_syscall_write/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 1000 write
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall write 2>&1 | sudo tee ./results/host/lat_syscall_write/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_write { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_write /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_syscall_write/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_syscall_write
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 100000 write > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_syscall_write/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_syscall_write/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_write /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_write /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_syscall_write/bpftrace.txt
sudo pkill -9 -x lat_syscall 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_syscall_write
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 100000 write > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_syscall | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_syscall_write/perf_stat.txt -- sleep 5
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

**Host Profiling:**
```bash
mkdir -p results/host/lat_ctx
sudo taskset -c 1 perf stat -o ./results/host/lat_ctx/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_ctx -P 1 -W 5 -N 1000 -s 32 2
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_ctx -s 32 2 2>&1 | sudo tee ./results/host/lat_ctx/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:sched:sched_switch { @counts[comm] = count(); }" | sudo tee ./results/host/lat_ctx/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_ctx
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_ctx -P 1 -W 5 -N 100000 -s 32 2 > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_ctx | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_ctx/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_ctx/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:sched:sched_switch /pid == $PID/ { @counts[comm] = count(); }" | sudo tee ./results/docker/lat_ctx/bpftrace.txt
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_ctx
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_ctx -P 1 -W 5 -N 100000 -s 32 2 > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_ctx | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_ctx/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_ctx/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:sched:sched_switch /pid == $PID/ { @counts[comm] = count(); }" | sudo tee ./results/k8s/lat_ctx/bpftrace.txt
sudo pkill -9 -x lat_ctx 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/host/lat_ctx/lat_ctx.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/docker/lat_ctx/lat_ctx.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_ctx -P 1 -W 5 -N 50 -s 32 2 -o results/k8s/lat_ctx/lat_ctx.txt
```

---

### 5. Metric: `lat_proc`

#### Phase 1: Profiling

**Host Profiling:**
```bash
mkdir -p results/host/lat_proc
sudo taskset -c 1 perf stat -o ./results/host/lat_proc/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_proc -P 1 -W 5 -N 1000 fork
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_proc fork 2>&1 | sudo tee ./results/host/lat_proc/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_clone { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_proc/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_proc
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_proc -P 1 -W 5 -N 100000 fork > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_proc | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_proc/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_proc/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_clone /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_proc/bpftrace.txt
sudo pkill -9 -x lat_proc 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_proc
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_proc -P 1 -W 5 -N 100000 fork > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_proc | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_proc/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/k8s/lat_proc/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_clone /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_clone /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/k8s/lat_proc/bpftrace.txt
sudo pkill -9 -x lat_proc 2>/dev/null || true
echo "[INFO] K8s profiling complete."
```

#### Phase 2: Official Benchmarks
```bash
CPU_CORE=1 sudo ./host_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/host/lat_proc/lat_proc.txt
CPU_CORE=1 sudo ./docker_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/docker/lat_proc/lat_proc.txt
CPU_CORE=1 sudo ./k8s_perf.sh lat_proc -P 1 -W 5 -N 50 fork -o results/k8s/lat_proc/lat_proc.txt
```

---

### 6. Metric: `lat_pagefault`

#### Phase 1: Profiling

**Host Profiling:**
```bash
mkdir -p results/host/lat_pagefault
sudo taskset -c 1 perf stat -o ./results/host/lat_pagefault/perf_stat.txt ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_pagefault -P 1 -W 5 -N 1000 /tmp/test
sudo strace -c -f ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_pagefault /tmp/test 2>&1 | sudo tee ./results/host/lat_pagefault/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_mmap { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_mmap /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/host/lat_pagefault/bpftrace.txt
```

**Docker Profiling:**
```bash
mkdir -p results/docker/lat_pagefault
echo "[INFO] Launching Docker benchmark in background..."
CPU_CORE=1 sudo ./docker_perf.sh lat_pagefault -P 1 -W 5 -N 100000 /tmp/test > /dev/null 2>&1 &
sleep 5
PID=$(pgrep -x lat_pagefault | tail -n 1)
echo "[INFO] Attaching to Container PID: $PID"
sudo perf stat -p $PID -o ./results/docker/lat_pagefault/perf_stat.txt -- sleep 5
sudo timeout 5s strace -c -p $PID 2>&1 | sudo tee ./results/docker/lat_pagefault/strace.txt
sudo timeout 10s bpftrace -e "tracepoint:syscalls:sys_enter_mmap /pid == $PID/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_mmap /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }" | sudo tee ./results/docker/lat_pagefault/bpftrace.txt
sudo pkill -9 -x lat_pagefault 2>/dev/null || true
echo "[INFO] Docker profiling complete."
```

**Kubernetes Profiling:**
```bash
mkdir -p results/k8s/lat_pagefault
echo "[INFO] Launching K8s benchmark in background..."
CPU_CORE=1 sudo ./k8s_perf.sh lat_pagefault -P 1 -W 5 -N 100000 /tmp/test > /dev/null 2>&1 &
sleep 15
PID=$(pgrep -x lat_pagefault | tail -n 1)
echo "[INFO] Attaching to K8s PID: $PID"
sudo perf stat -p $PID -o ./results/k8s/lat_pagefault/perf_stat.txt -- sleep 5
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
