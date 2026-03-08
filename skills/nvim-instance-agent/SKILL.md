---
name: nvim-instance-agent
description: Control the current Neovim instance through instance-scoped environment variables and run unrestricted remote actions with full observability logs.
---

# Nvim Instance Agent

## When to use

Use this skill when:

- You are in a terminal launched from Neovim and want to control that exact instance.
- You need high autonomy (few action restrictions) but still need traceability.

## Required environment contract

Read these variables from the current shell:

- `NVIM_LISTEN_ADDRESS`
- `NVIM_INSTANCE_ID`
- `NVIM_AGENT=1`
- `NVIM_AGENT_LOG_FILE` (preferred) or `NVIM_AGENT_LOG_DIR`

If `NVIM_LISTEN_ADDRESS` is empty, fail fast with a clear error.

## Execution rule (mandatory)

For every remote action, use the wrapper script so each call is logged:

```bash
scripts/nvim_agent_exec.sh <nvr args...>
```

Examples:

```bash
scripts/nvim_agent_exec.sh --remote path/to/file
scripts/nvim_agent_exec.sh --remote-send '<Esc>:wa<CR>'
scripts/nvim_agent_exec.sh --remote-expr 'getcwd()'
```

This wrapper:

- Ensures server connectivity (`scripts/nvim_agent_ensure.sh`)
- Executes `nvr --servername "$NVIM_LISTEN_ADDRESS" ...`
- Appends a log record with rc, duration, output/error bytes, args, and stderr sample

## Observability

View logs:

```bash
scripts/nvim_agent_logs.sh --tail 120
```

Log format is tab-separated key-value fields. Parse with grep/awk as needed.

## Policy

- Capability is intentionally open (no strict action allowlist by default).
- Always preserve observability by routing calls through `nvim_agent_exec.sh`.
