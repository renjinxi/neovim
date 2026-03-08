#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvr >/dev/null 2>&1; then
  echo "nvr not found. Install: pipx install neovim-remote" >&2
  exit 1
fi

SOCK="${NVIM_LISTEN_ADDRESS:-}"

if [[ -z "${SOCK}" ]]; then
  echo "NVIM_LISTEN_ADDRESS is empty; export it before calling this script." >&2
  exit 2
fi

sock_dir="$(dirname "${SOCK}")"
mkdir -p "${sock_dir}"

probe() {
  nvr --servername "${SOCK}" --remote-expr '1' >/dev/null 2>&1
}

if ! probe; then
  nohup nvim --headless --listen "${SOCK}" >/tmp/nvim-agent-headless.log 2>&1 &
  for _ in $(seq 1 100); do
    if probe; then
      break
    fi
    sleep 0.03
  done
fi

if ! probe; then
  echo "failed to connect to ${SOCK}" >&2
  exit 3
fi

echo "${SOCK}"
