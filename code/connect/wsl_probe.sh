#!/usr/bin/env bash
# Probe the HPC targets from inside WSL, where the previous working SSH setup
# lives. Read-only: BatchMode only, so it never blocks on a password prompt.
# Usage: bash wsl_probe.sh <outfile>
out="${1:-/tmp/wsl_probe.txt}"
: >"$out"
exec >>"$out" 2>&1

echo "DISTRO=$( (lsb_release -ds 2>/dev/null || grep PRETTY /etc/os-release) | tr -d '\"' )"
echo "USER=$USER HOST=$(hostname)"
echo "TOOLS ssh=$(command -v ssh) rsync=$(command -v rsync) sshpass=$(command -v sshpass) jq=$(command -v jq) sbatch=$(command -v sbatch)"
echo "HAS_PASSFILE=$( [ -f "$HOME/.hpc_pass" ] && echo yes || echo no )"

echo "--- config host aliases ---"
grep -iE '^[[:space:]]*Host[[:space:]]' "$HOME/.ssh/config" 2>/dev/null | sed 's/^[[:space:]]*Host[[:space:]]*//' | tr '\n' ',' ; echo
echo "--- keys ---"
for k in "$HOME"/.ssh/id_*; do
  case "$k" in *.pub) continue;; esac
  [ -f "$k" ] && echo "$(basename "$k") $(ssh-keygen -l -f "$k" 2>/dev/null | cut -d' ' -f1)"
done

try() { # label, timeout-ssh-args...
  local label="$1"; shift
  echo "=== $label ==="
  timeout 30 ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$@" \
    'echo AUTH_OK; hostname; whoami; echo HOME=$HOME; echo SINODES; sinfo -h -N 2>/dev/null | head -3 || echo no-sinfo' 2>&1
  echo "rc=$?"
}

try "mu01 (alias in w26 config)" mu01
try "25wenshaohua@10.10.5.210 (id_ed25519)" -o IdentitiesOnly=yes -i "$HOME/.ssh/id_ed25519" 25wenshaohua@10.10.5.210
try "BNI@192.168.1.109 (id_ed25519)" -o IdentitiesOnly=yes -i "$HOME/.ssh/id_ed25519" BNI@192.168.1.109
try "w24e@192.168.1.109 (id_ed25519)" -o IdentitiesOnly=yes -i "$HOME/.ssh/id_ed25519" w24e@192.168.1.109

echo "=== TCP 22 ==="
for h in 10.10.5.210 192.168.1.109; do
  timeout 8 bash -c "cat < /dev/null > /dev/tcp/$h/22" >/dev/null 2>&1 && echo "$h open" || echo "$h closed"
done
echo "PROBE_DONE"
