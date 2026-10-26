#!/usr/bin/env bash
# agent-hub.sh - one-command Arena <-> Windows host (git-sync-hub v4.0) bridge.
#
# Dispatches local file writes/copies and code execution (PowerShell / Python /
# Bash / CMD) to the permanent background watcher `git-sync-hub` running 24/7
# on the user's Windows machine (LAPTOP-R77M5D6M), waits for the host to pull,
# execute silently (CREATE_NO_WINDOW), archive to E:\0github\results\<repo-branch>\,
# and push back `results/status/hub_sync_receipt.json` + `results/status/hub_exec_output.txt`,
# then fast-forwards the current branch so the results are in the working tree.
#
# Examples:
#   bash skills/git-sync/scripts/agent-hub.sh \
#     --write 'C:\0github\hello.txt' 'Hello from Arena!' \
#     --ps 'Get-Item C:\0github\hello.txt | Select-Object FullName,Length'
#
#   bash skills/git-sync/scripts/agent-hub.sh \
#     --copy 'deliverable/report.md' 'D:\桌面\report.md' \
#     --py 'import platform; print(platform.node())'
#
#   bash skills/git-sync/scripts/agent-hub.sh --run-task

set -u -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
cd "$REPO_ROOT"

BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
REMOTE="origin"
if [ -f "skills/git-sync/sync.config.json" ]; then
  REMOTE="$(python3 -c "import json;print(json.load(open('skills/git-sync/sync.config.json',encoding='utf-8')).get('remote','origin'))" 2>/dev/null || echo origin)"
fi
case "$BRANCH" in
  main|master|HEAD|'')
    echo "[REFUSED] must be on an arena/* working branch (current: '$BRANCH')" >&2
    exit 1 ;;
esac

MSG="feat(hub): dispatch local task to git-sync-hub v4.0"
TIMEOUT=180
INTERVAL=5
RUN_EXISTING=0

WRITES_JSON="[]"
COPIES_JSON="[]"
PS_JSON="[]"
PY_JSON="[]"
SH_JSON="[]"
CMD_JSON="[]"

json_append_obj2() {
  python3 - "$1" "$2" "$3" "$4" "$5" <<'PY'
import json, sys
arr = json.loads(sys.argv[1])
arr.append({sys.argv[2]: sys.argv[3], sys.argv[4]: sys.argv[5]})
print(json.dumps(arr, ensure_ascii=False))
PY
}

json_append_str() {
  python3 - "$1" "$2" <<'PY'
import json, sys
arr = json.loads(sys.argv[1])
arr.append(sys.argv[2])
print(json.dumps(arr, ensure_ascii=False))
PY
}

while [ $# -gt 0 ]; do
  case "$1" in
    --write)
      WRITES_JSON="$(json_append_obj2 "$WRITES_JSON" path "$2" content "$3")"
      shift 3 ;;
    --copy)
      COPIES_JSON="$(json_append_obj2 "$COPIES_JSON" source "$2" target "$3")"
      shift 3 ;;
    --ps|--powershell)
      PS_JSON="$(json_append_str "$PS_JSON" "$2")"
      shift 2 ;;
    --py|--python)
      PY_JSON="$(json_append_str "$PY_JSON" "$2")"
      shift 2 ;;
    --sh|--bash)
      SH_JSON="$(json_append_str "$SH_JSON" "$2")"
      shift 2 ;;
    --cmd)
      CMD_JSON="$(json_append_str "$CMD_JSON" "$2")"
      shift 2 ;;
    --run-task)
      RUN_EXISTING=1
      shift ;;
    --msg)
      MSG="$2"
      shift 2 ;;
    --timeout)
      TIMEOUT="$2"
      shift 2 ;;
    --interval)
      INTERVAL="$2"
      shift 2 ;;
    -h|--help)
      sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      if [ "$WRITES_JSON" != "[]" ] || [ "$COPIES_JSON" != "[]" ] || [ "$PS_JSON" != "[]" ] || [ "$PY_JSON" != "[]" ] || [ "$SH_JSON" != "[]" ] || [ "$CMD_JSON" != "[]" ]; then
        echo "[NOTE] ignoring trailing argument: $1" >&2
        shift
      else
        echo "[ERROR] unknown option: $1" >&2
        exit 1
      fi ;;
  esac
done

mkdir -p results/status
TASK_FILE="results/status/hub_task.json"

python3 - "$TASK_FILE" "$RUN_EXISTING" "$WRITES_JSON" "$COPIES_JSON" "$PS_JSON" "$PY_JSON" "$SH_JSON" "$CMD_JSON" <<'PY'
import datetime, json, os, sys

task_file, run_existing, writes_s, copies_s, ps_s, py_s, sh_s, cmd_s = sys.argv[1:9]
writes = json.loads(writes_s)
copies = json.loads(copies_s)
ps_list = json.loads(ps_s)
py_list = json.loads(py_s)
sh_list = json.loads(sh_s)
cmd_list = json.loads(cmd_s)

if run_existing == "1" and os.path.isfile(task_file):
    data = json.load(open(task_file, encoding="utf-8-sig"))
else:
    data = {}

data["enabled"] = True
data["status"] = "pending"
data["request_id"] = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

if writes:
    data["write_files"] = writes
if copies:
    data["copy_files"] = copies

# Auto-verify written/copied targets with Get-Item FullName,Length when no explicit --ps was given
if (writes or copies) and not ps_list:
    verify_cmds = []
    for wf in writes:
        p = wf.get("path", "").replace("'", "''")
        if p:
            verify_cmds.append(f"Get-Item -LiteralPath '{p}' -ErrorAction SilentlyContinue | Select-Object FullName,Length")
    for cf in copies:
        p = cf.get("target", "").replace("'", "''")
        if p:
            verify_cmds.append(f"Get-Item -LiteralPath '{p}' -ErrorAction SilentlyContinue | Select-Object FullName,Length")
    if verify_cmds:
        ps_list = ["; ".join(verify_cmds)]

if ps_list:
    data["powershell"] = ps_list
if py_list:
    data["python"] = py_list
if sh_list:
    data["bash"] = sh_list
if cmd_list:
    data["cmd"] = cmd_list

for k in ("executed_on_host", "executed_at_utc", "executed_at_local", "source_commit", "written_paths"):
    data.pop(k, None)

with open(task_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("== prepared", task_file, "request_id=" + data["request_id"])
PY

# Push to remote branch
if [ -f "$HERE/agent-sync.sh" ] && [ -f "skills/git-sync/sync.config.json" ]; then
  bash "$HERE/agent-sync.sh" "$MSG" || {
    git add -A
    git commit -m "$MSG" --allow-empty
    git push "$REMOTE" "$BRANCH"
  }
else
  git add -A
  git commit -m "$MSG" --allow-empty
  git push "$REMOTE" "$BRANCH"
fi

PUSHED_SHA="$(git rev-parse HEAD)"
echo "== pushed commit $PUSHED_SHA to $REMOTE/$BRANCH"
echo "== waiting for git-sync-hub v4.0 on Windows host (polling every ${INTERVAL}s, max ${TIMEOUT}s) ..."

tip_sha() {
  git ls-remote "$REMOTE" "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}'
}

start=$SECONDS
while true; do
  slept=$((SECONDS - start))
  if [ "$slept" -ge "$TIMEOUT" ]; then
    echo ""
    echo "[TIMEOUT] waited ${TIMEOUT}s and remote tip is still $PUSHED_SHA" >&2
    exit 3
  fi
  sleep "$INTERVAL"
  REMOTE_SHA="$(tip_sha)"
  if [ -n "$REMOTE_SHA" ] && [ "$REMOTE_SHA" != "$PUSHED_SHA" ]; then
    echo ""
    echo "== host pushed commit $REMOTE_SHA (after ${slept}s) - pulling results ..."
    git fetch "$REMOTE" "$BRANCH" --quiet
    git merge --ff-only FETCH_HEAD --quiet || git reset --hard FETCH_HEAD
    break
  fi
  printf '  [%3ds/%ds] waiting for host execution ...\r' "$slept" "$TIMEOUT"
done

if [ -f "results/status/hub_exec_output.txt" ]; then
  echo ""
  echo "==================== hub_exec_output.txt ===================="
  cat "results/status/hub_exec_output.txt"
fi

if [ -f "results/status/hub_sync_receipt.json" ]; then
  echo ""
  echo "==================== hub_sync_receipt.json =================="
  cat "results/status/hub_sync_receipt.json"
  ALL_OK="$(python3 -c "import json;d=json.load(open('results/status/hub_sync_receipt.json',encoding='utf-8-sig'));print(str(d.get('tasks_all_ok',True)).lower())" 2>/dev/null || echo true)"
  if [ "$ALL_OK" = "false" ]; then
    exit 2
  fi
fi

exit 0
