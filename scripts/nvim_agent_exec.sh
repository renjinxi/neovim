#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <nvr args...>" >&2
  exit 64
fi

if ! command -v nvr >/dev/null 2>&1; then
  echo "nvr not found. Install: pipx install neovim-remote" >&2
  exit 1
fi

SOCK="$("${SCRIPT_DIR}/nvim_agent_ensure.sh")"
INSTANCE_ID="${NVIM_INSTANCE_ID:-unknown}"
LOG_DIR="${NVIM_AGENT_LOG_DIR:-$HOME/.local/state/nvim/agent-logs}"
LOG_FILE="${NVIM_AGENT_LOG_FILE:-${LOG_DIR}/agent-exec-${INSTANCE_ID}.log}"
mkdir -p "${LOG_DIR}"

now_ms() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
    return
  fi
  # macOS date 没有稳定的毫秒输出，这里退化到秒
  echo "$(( $(date +%s) * 1000 ))"
}

ts_start="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
start_ms="$(now_ms)"

out_file="$(mktemp /tmp/nvim-agent-out.XXXXXX)"
err_file="$(mktemp /tmp/nvim-agent-err.XXXXXX)"
trap 'rm -f "${out_file}" "${err_file}"' EXIT

set +e
nvr --servername "${SOCK}" "$@" >"${out_file}" 2>"${err_file}"
rc=$?
set -e

end_ms="$(now_ms)"
duration_ms=$((end_ms - start_ms))

out_bytes="$(wc -c < "${out_file}" | tr -d '[:space:]')"
err_bytes="$(wc -c < "${err_file}" | tr -d '[:space:]')"
stderr_sample="$(head -c 200 "${err_file}" | tr '\n' ' ' | tr '\t' ' ' | tr '\r' ' ')"

args_q=""
for a in "$@"; do
  q="$(printf '%q' "$a")"
  if [[ -z "${args_q}" ]]; then
    args_q="${q}"
  else
    args_q="${args_q} ${q}"
  fi
done

printf '%s\tevent=agent_exec\tinstance=%s\tsocket=%s\tcwd=%s\trc=%s\tduration_ms=%s\tout_bytes=%s\terr_bytes=%s\targs=%s\tstderr_sample=%s\n' \
  "${ts_start}" "${INSTANCE_ID}" "${SOCK}" "${PWD}" "${rc}" "${duration_ms}" "${out_bytes}" "${err_bytes}" "${args_q}" "${stderr_sample}" \
  >> "${LOG_FILE}"

cat "${out_file}"
cat "${err_file}" >&2
exit "${rc}"
