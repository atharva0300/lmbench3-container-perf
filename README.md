# lmbench3-container-perf
Performance Profiling of Host and Containerized Systems Using LMbench3

# Configurations
1. Setup the GRUB_CMDLINE_LINUX_DEFAULT in the file /etc/default/grub
```
GRUB_CMDLINE_LINUX_DEFAULT="autoinstall ds=nocloud\\;s=/cdrom/ quiet splash noprompt noshell automatic-ubiquity debian-installer/locale=en_US keyboard-configuration/layoutcode=us languagechooser/language-name=English localechooser/supported-locales=en_US.UTF-8 countrychooser/shortlist=IN -- isolcpus=1-3 nohz_full=1-3 rcu_nocbs=1-3"
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
``

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
