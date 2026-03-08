#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${NVIM_AGENT_LOG_FILE:-}"
if [[ -z "${LOG_FILE}" ]]; then
  LOG_DIR="${NVIM_AGENT_LOG_DIR:-$HOME/.local/state/nvim/agent-logs}"
  if [[ -n "${NVIM_INSTANCE_ID:-}" ]]; then
    LOG_FILE="${LOG_DIR}/agent-exec-${NVIM_INSTANCE_ID}.log"
  fi
fi

if [[ -z "${LOG_FILE}" ]]; then
  echo "cannot determine log file; set NVIM_AGENT_LOG_FILE" >&2
  exit 2
fi

if [[ ! -f "${LOG_FILE}" ]]; then
  echo "log file not found: ${LOG_FILE}" >&2
  exit 3
fi

if [[ "${1:-}" == "--tail" ]]; then
  n="${2:-80}"
  tail -n "${n}" "${LOG_FILE}"
  exit 0
fi

cat "${LOG_FILE}"
