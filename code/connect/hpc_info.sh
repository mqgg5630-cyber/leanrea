#!/usr/bin/env bash
# Inventory of the campus HPC (mu01) reached over the existing WSL ssh alias.
# Read-only. Usage: bash hpc_info.sh <outfile>
out="${1:-/tmp/hpc_info.txt}"
: >"$out"
exec >>"$out" 2>&1

SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new mu01"
echo "=== whoami ==="
$SSH 'hostname; whoami; uname -srm; echo; echo "SLURM:"; sinfo --version; sbatch --version; squeue --version; echo; echo "PARTITIONS:"; sinfo -s; echo; echo "PARTITION DETAIL:"; scontrol show partition 2>/dev/null | grep -E "PartitionName|MaxTime|MaxNodes|Default|State|TRES|MaxMemPerNode|NodeList" | head -40; echo; echo "MY JOBS:"; squeue -u $USER; echo; echo "RECENT:"; sacct -u $USER -S now-7days -n -X --format=JobID,JobName%22,State,Elapsed,Partition 2>/dev/null | tail -8' 2>&1

echo
echo "=== storage / env ==="
$SSH 'echo HOME=$HOME; df -h $HOME /tmp 2>/dev/null; echo; echo "QUOTA:"; (quota -s 2>/dev/null || lfs quota -h -u $USER $HOME 2>/dev/null || echo no-quota-tool) | head -6; echo; echo "MODULES:"; (module avail 2>&1 | head -25) || echo no-modules; echo; echo "STACK:"; for c in python3 conda mamba apptainer singularity java gcc nvcc; do printf "%-10s %s\n" "$c" "$(command -v $c || echo -)"; done' 2>&1

echo
echo "=== existing project dirs ==="
$SSH 'ls -d $HOME/* 2>/dev/null | head -20; echo; du -sh $HOME 2>/dev/null | tail -1; echo; ls -d $HOME/wsh/ad/* 2>/dev/null | head' 2>&1

echo "=== r2 (second host 192.168.1.109) tcp banners ==="
for p in 22 2222 5985 3389 445 8080; do
  timeout 4 bash -c "exec 3<>/dev/tcp/192.168.1.109/$p && head -c 60 <&3" 2>/dev/null | tr -d '\0' | head -1 | sed "s/^/port $p banner: /"
  rc=$?
  [ $rc -ne 0 ] && echo "port $p banner: <none>"
done
echo "HPC_INFO_DONE"
