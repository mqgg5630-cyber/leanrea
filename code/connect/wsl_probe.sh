#!/usr/bin/env bash
# Probe the two HPC targets from inside WSL, where the previous working SSH
# setup lives (key ~/.ssh/id_ed25519, Host mu01). Read-only: BatchMode only,
# so it never blocks on a password prompt.
# Usage: bash wsl_probe.sh <outfile>
out="${1:-/tmp/wsl_probe.txt}"
exec >"$out" 2>&1

echo "DISTRO=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY | cut -d= -f2)"
echo "USER=$USER HOST=$(hostname)"
echo "TOOLS ssh=$(command -v ssh) rsync=$(command -v rsync) sshpass=$(command -v sshpass) jq=$(command -v jq)"
echo "--- ~/.ssh ---"
ls -l ~/.ssh 2>/dev/null | awk '{print $1, $5, $9}'
echo "--- config hosts ---"
grep -E '^\s*(Host|HostName|User|Port|IdentityFile)' ~/.ssh/config 2>/dev/null | tr -s ' ' | tr '\n' '|'
echo
echo "--- keys available ---"
for k in ~/.ssh/id_*; do case "$k" in *.pub) ;; *) [ -f "$k" ] && echo "$k $(ssh-keygen -l -f "$k" 2>/dev/null | cut -d' ' -f1-2)";; esac; done

echo "--- targets from ~/.ssh/config (host aliases) ---"
grep -iE '^\s*Host\s' ~/.ssh/config 2>/dev/null | sed 's/^\s*Host\s\+//'

for tgt in mu01 25wenshaohua 10.10.5.210; do
  echo "=== TCP $tgt:22 ==="
  timeout 8 bash -c "cat < /dev/null > /dev/tcp/$tgt/22" 2>&1 && echo "tcp=open" || echo "tcp=fail"
  echo "=== SSH $tgt (BatchMode, 20s) ==="
  timeout 25 ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
      "$tgt" 'echo AUTH_OK; hostname; whoami; uname -r; echo SINFO; sinfo -V 2>/dev/null || echo no-slurm; echo HOME=$HOME; ls -d ~/* 2>/dev/null | head -5' 2>&1
  echo "rc=$?"
done

for tgt in 192.168.1.109 BNI@192.168.1.109; do
  echo "=== TCP/SSH $tgt ==="
  timeout 8 bash -c "cat < /dev/null > /dev/tcp/192.168.1.109/22" 2>&1 && echo "tcp=open" || echo "tcp=fail"
  timeout 20 ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$tgt" \
      'echo AUTH_OK; hostname; whoami; uname -a' 2>&1
  echo "rc=$?"
  break
done

echo "PROBE_DONE"
