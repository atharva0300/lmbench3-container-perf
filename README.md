# lmbench3-container-perf
Performance Profiling of Host and Containerized Systems Using LMbench3

# Configurations
1. Setup the GRUB_CMDLINE_LINUX_DEFAULT in the file /etc/default/grub
```
GRUB_CMDLINE_LINUX_DEFAULT="autoinstall ds=nocloud\\;s=/cdrom/ quiet splash noprompt noshell automatic-ubiquity debian-installer/locale=en_US keyboard-configuration/layoutcode=us languagechooser/language-name=English localechooser/supported-locales=en_US.UTF-8 countrychooser/shortlist=IN -- isolcpus=1-3 nohz_full=1-3 rcu_nocbs=1-3"
```
# Build the Project
1. Get inside the lmbench folder: ```cd lmbench-3.0-a9```
2. Build: ```make CFLAGS="-g -O0"```
The executables will be inside `bin/x86_64-linux-gnu`

# Running the benchmark
1. On host: 
	```
	CPU_CORE=1 sudo ./host_perf.sh lat_syscall -P 1 -W 5 -N 10 null
	```


# Observability Tools
`perf` 
## Using perf on host: 
1. perf stat: 
```
sudo taskset -c 1 perf stat ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 100 null
```
2. perf record: 
```
sudo taskset -c 1 perf record -g ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 100 null
```

The above are example commands for lat_syscall, for the other benchmarks, do the needful changes. 

3. perf report: (ensure that the perf.data is present in the present working directory) 
```
sudo perf report
```

## Using perf on docker: 
1. perf stat: 
```
docker run --rm \
--cpuset-cpus="1" \
-v $(pwd)/lmbench-3.0-a9:/lmbench \
--privileged \
ubuntu:20.04 \
sudo perf stat /lmbench/bin/x86_64-linux-gnu/lat_syscall -P 1 -W 5 -N 100 null
```


## Using perf on k8s: 
1. perf stat: 
	- ```
	  kubectl get pod <pod-name> -o wide
	  ```
	- ```
	  crictl inspect <container-id> | grep pid
	  ```	
	- ```
	  sudo perf stat -p <PID>
	  ```

## Benchmarks and Args
1. lat_syscall : time simple entry into the operating system. [manpage](https://lmbench.sourceforge.net/man/lat_syscall.8.html) 
	- `-P 1 -W 5 -N 20 null` : measures how long it takes to do getppid().
	- `-P 1 -W 5 -N 20 read` : measures how long it takes to read one byte from CB/dev/zero.
	- `-P 1 -W 5 -N 20 write` : measures times how long it takes to write one byte to CB/dev/null.
	- `-P 1 -W 5 -N 20 stat` : measures how long it takes to stat() a file whose inode is already cached.
	- `-P 1 -W 5 -N 20 fstat` : measures how long it takes to fstat() an open file whose inode is already cached.
	- `-P 1 -W 5 -N 20 open` : measures how long it takes to open() and then close() a file.

2. future: lat_ctx, lat_proc, lat_pagefault, lat_pipe/lat_unix, lat_tcp, lat_udp (not to implement all but good choices for a visible output difference between host, docker and k8
