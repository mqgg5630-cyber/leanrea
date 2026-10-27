#!/usr/bin/env bash
# Verify the download path and diagnose the second host 192.168.1.109.
# Usage: bash verify_all.sh <outfile>
out="${1:-/tmp/verify.txt}"
: >"$out"
exec >>"$out" 2>&1
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new mu01"

echo "=== A. rsync download from HPC ==="
mkdir -p /mnt/e/0apps/jev-chat-windows/tools/fetched
rsync -az -e ssh "mu01:~/jobs/smoke_92384.out" /mnt/e/0apps/jev-chat-windows/tools/fetched/ && echo DOWNLOAD_OK
echo "local copy:"; ls -l /mnt/e/0apps/jev-chat-windows/tools/fetched/ 2>/dev/null
head -3 /mnt/e/0apps/jev-chat-windows/tools/fetched/smoke_92384.out 2>/dev/null

echo
echo "=== B. 192.168.1.109 diagnosis ==="
for p in 22 2222 3389 5985 5986 445 80; do
  r=$(timeout 4 bash -c "exec 3<>/dev/tcp/192.168.1.109/$p 2>/dev/null && head -c 40 <&3" 2>/dev/null | tr -d '\0\r' | head -1)
  if [ -n "$r" ]; then echo "port $p banner: $r"; else echo "port $p : no-banner"; fi
done
echo "-- verbose ssh --"
timeout 15 ssh -vv -o BatchMode=yes -o ConnectTimeout=6 BNI@192.168.1.109 true 2>&1 | grep -Ei 'banner|kex|closed|denied|version|Connecting' | head -8

echo
echo "=== C. tailscale peers ==="
if command -v tailscale.exe >/dev/null 2>&1; then echo skip; fi
/mnt/c/Program\ Files/Tailscale/tailscale.exe status --peers 2>/dev/null | grep -Ei 'desktop|muse|100\.' | head -6

echo
echo "=== D. HPC quick facts ==="
$SSH 'echo host=$(hostname); scontrol show node cu46 2>/dev/null | grep -E "CPUTot|RealMemory|Gres" | head -3; echo; scontrol show node fat01 2>/dev/null | grep -E "CPUTot|RealMemory|Gres" | head -3'
echo VERIFY_DONE
