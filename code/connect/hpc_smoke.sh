#!/usr/bin/env bash
# End-to-end proof of the laptop -> HPC path: upload a batch script, submit it,
# poll Slurm, fetch the output. Usage: bash hpc_smoke.sh <outfile>
out="${1:-/tmp/hpc_smoke.txt}"
: >"$out"
exec >>"$out" 2>&1

SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new mu01"
RS="rsync -az -e ssh"
LOCAL_DIR=/mnt/e/0apps/jev-chat-windows/tools
echo "=== 1. prepare remote dirs ==="
$SSH 'mkdir -p ~/jobs && echo REMOTE_DIR_OK; ls -d ~/jobs'

echo "=== 2. upload smoke.sbatch ==="
$RS "$LOCAL_DIR/smoke.sbatch" mu01:~/jobs/ && echo UPLOAD_OK
$SSH 'ls -l ~/jobs/smoke.sbatch'

echo "=== 3. submit ==="
JID=$($SSH 'cd ~/jobs && sbatch smoke.sbatch' | tail -1 | awk '{print $NF}')
echo "JOBID=$JID"
[ -z "$JID" ] && { echo "SUBMIT_FAILED"; exit 1; }

echo "=== 4. poll ==="
for i in $(seq 1 40); do
  st=$($SSH "squeue -j $JID -h -o %T 2>/dev/null")
  echo "poll $i state=${st:-<gone>}"
  case "$st" in
    ""|COMPLETED|FAILED|CANCELLED*) break;;
  esac
  sleep 6
done

echo "=== 5. accounting ==="
$SSH "sacct -j $JID --format=JobID,JobName%18,State,ExitCode,Elapsed,NodeList -n 2>/dev/null | head -4"

echo "=== 6. fetch result ==="
$SSH "cat ~/jobs/smoke_$JID.out 2>/dev/null; echo '--- stderr ---'; cat ~/jobs/smoke_$JID.err 2>/dev/null | head -5"
$RS "mu01:~/jobs/smoke_$JID.out" "$LOCAL_DIR/hpc_smoke_result.txt" 2>/dev/null && echo FETCH_OK
echo "SMOKE_DONE JOBID=$JID"
