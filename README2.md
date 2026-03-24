# lmbench3-container-perf

Performance Profiling and Comparative Analysis of **Host vs Docker vs Kubernetes** using **LMbench3** and Linux Observability Tools.

---

# Objective

This project aims to:

- Benchmark low-level system performance using **LMbench3**
- Compare performance across:
  - Host system
  - Docker containers
  - Kubernetes pods
- Perform **in-depth analysis** of:
  - Syscall latency
  - Scheduling overhead
  - Memory behavior
  - Variability in measurements
- Use observability tools to **explain *why* differences occur**, not just report numbers

---

# Tech Stack

- **LMbench3** (micro-benchmarking suite)
- **Docker** (container runtime)
- **Kubernetes** (container orchestration)
- **perf** (Linux performance profiling)
- **strace** (syscall tracing)
- **bpftrace** (kernel tracing)
- Linux kernel features:
  - cgroups
  - namespaces
  - scheduler

---

# System Configuration (VERY IMPORTANT)

To reduce variability and obtain reliable results:

## 1. CPU Isolation

Edit `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash isolcpus=1-3 nohz_full=1-3 rcu_nocbs=1-3"
```

Then update:

```bash
sudo update-grub
sudo reboot
```

---

## 2. CPU Frequency & Turbo

```bash
sudo cpupower frequency-set -g performance
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

---

## 3. perf Permissions

```bash
sudo sysctl -w kernel.perf_event_paranoid=-1
sudo sysctl -w kernel.kptr_restrict=0
```

---

# Build LMbench

```bash
cd lmbench-3.0-a9
make CFLAGS="-g -O0"
```

Executables:

```
bin/x86_64-linux-gnu/
```

---

# Running Benchmarks

## Recommended Approach

Scripts accept **dynamic arguments**:

```bash
./host_perf.sh <benchmark> [args...]
./docker_perf.sh <benchmark> [args...]
./k8s_perf.sh <benchmark> [args...]
```

---

## Host

```bash
CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 50 null
```

---

## Docker

```bash
sudo ./docker_perf.sh lat_syscall -P 1 -W 5 -N 50 null
```

---

## Kubernetes

```bash
sudo ./k8s_perf.sh lat_syscall -P 1 -W 5 -N 50 null
```

---

# Observability Tools

---

## perf

### 1. perf stat

```bash
sudo taskset -c 1 perf stat ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 100 null
```

---

### 2. perf record (call graph)

```bash
sudo taskset -c 1 perf record -F 999 -g ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 100 null
```

---

### 3. perf report

```bash
sudo perf report --call-graph=graph
```

Shows full syscall path:

```
User → libc → syscall entry → kernel → return
```

---

## strace

```bash
strace -c -f ./lat_syscall null
```

Shows:

* syscall distribution
* frequency
* time spent per syscall

---

## bpftrace

Example (syscall latency histogram):

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_getppid { @start[tid] = nsecs; }
tracepoint:syscalls:sys_exit_getppid /@start[tid]/ {
  @lat = hist(nsecs - @start[tid]);
  delete(@start[tid]);
}'
```

---

# Benchmark Selection

---

## High Impact Benchmarks (RECOMMENDED)

| Benchmark         | Measures         | Why Important                 |
| ----------------- | ---------------- | ----------------------------- |
| lat_syscall       | syscall latency  | kernel entry/exit overhead    |
| lat_ctx           | context switch   | scheduler overhead            |
| lat_proc          | process creation | namespace + fork cost         |
| lat_pagefault     | memory faults    | memory management             |
| lat_tcp / lat_udp | networking       | container networking overhead |

---

# Analysis Methodology

## Step 1: Run Benchmark

* Run **multiple iterations (≥10)**
* Use CPU pinning (`taskset`)
* Keep system idle

---

## Step 2: Collect Data

Each run stores:

* system configuration
* raw benchmark outputs
* multiple runs

---

## Step 3: Statistical Analysis

For each benchmark:

### Central Tendency

* Use **median** (robust)
* Use mean only if stable

### Variability Metrics

| Metric                        | Use Case                 |
| ----------------------------- | ------------------------ |
| Standard deviation            | basic variability        |
| Coefficient of Variation (CV) | compare environments     |
| Percentiles (5th, 95th)       | tail latency             |
| SIQR                          | non-normal distributions |

---

## Step 4: Interpret Results

---

### Example (lat_syscall)

```
Host < Docker < Kubernetes
```

Reason:

* syscall path includes kernel
* cgroups add accounting
* K8s adds orchestration overhead

---

### Example (lat_ctx)

* Higher in Kubernetes due to scheduler + pod isolation

---

### Example (lat_tcp)

* Docker: bridge network overhead
* Kubernetes: overlay network → **highest latency**

---

# Variability (VERY IMPORTANT)

---

## What is variability?

Variation in benchmark results across runs.

---

## Causes

* scheduler interference
* interrupts
* background processes
* virtualization (KVM)
* container orchestration

---

## Detection

Run multiple times:

```bash
Run 1: 0.13 µs
Run 2: 0.17 µs
Run 3: 0.14 µs
```

---

## Reduction Techniques

* CPU isolation (`isolcpus`)
* CPU pinning (`taskset`)
* disable turbo boost
* run on idle system

---

---

# Project Structure

```
.
├── host_perf.sh
├── docker_perf.sh
├── k8s_perf.sh
├── lmbench-3.0-a9/
├── results/
└── README.md
```

---

# Key Insight

---

> Not all benchmarks show container overhead.

---

* **Hardware-bound → no difference**
* **Kernel/scheduler/network → clear difference**

---

---

# Final Takeaway

---

This project demonstrates that:

* Containers introduce **measurable overhead**
* Kubernetes introduces **additional variability and latency**
* Observability tools are essential to **explain performance behavior**

---

# Author

Atharva Pingale


