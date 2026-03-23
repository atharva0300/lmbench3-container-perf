# lmbench3-container-perf
Performance Profiling of Host and Containerized Systems Using LMbench3

# Observability Tools
`perf` 
## Using perf on host: 
1. perf stat: 
```
taskset -c 1 perf stat ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall null -P 1 -W 5 -N 50
```
2. perf record: 
```
taskset -c 1 perf record -g ./lmbench-3.0-a9/bin/x86_64-linux-gnu/lat_syscall null -P 1 -W 5 -N 50
```

The above are example commands for lat_syscall, for the other benchmarks, do the needful changes. 

## Using perf on docker: 
1. perf stat: 
```
docker run --rm \
--cpuset-cpus="1" \
-v $(pwd)/lmbench-3.0-a9:/lmbench \
--privileged \
ubuntu:20.04 \
perf stat /lmbench/bin/x86_64-linux-gnu/lat_syscall null -P 1 -W 5 -N 50
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
