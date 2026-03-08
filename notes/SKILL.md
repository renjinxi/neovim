---
name: nvim-instance-agent
description: Control the current Neovim instance via structured RPC API. All calls return JSON, no quote-escaping hell.
---

# Nvim Instance Agent

## When to use

You are in a terminal spawned by Neovim and want to control that instance.

## Environment contract

Required variables (inherited from nvim's `:terminal`):

- `NVIM_LISTEN_ADDRESS` — socket path (fail fast if empty)
- `NVIM_AGENT_API=1` — confirms agent_api.lua is loaded

## Calling convention

All functions live in `require("core.agent_api")`. Every call returns JSON: `{"ok":true,"data":...}` or `{"ok":false,"error":"..."}`.

Use single-quote wrapping for `--remote-expr`. Inside single quotes, use `\"` for lua string delimiters.

```bash
SOCK="$NVIM_LISTEN_ADDRESS"
API='require("core.agent_api")'
CALL='luaeval("require(\"core.agent_api\").exec_lua(_A)"'
```

### No-arg functions — call directly

```bash
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").get_context()")'
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").get_buffers()")'
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").get_diagnostics()")'
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").list_terminals()")'
```

### String arg via _A

```bash
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").notify(_A)", "Hello")'
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").open_file(_A)", "/path/to/file:50")'
```

### Complex args — use exec_lua

When you need tables/arrays, wrap with `exec_lua`:

```bash
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").get_diagnostics({severity = 1})")'
```

## API reference

| Function | Args | Notes |
|---|---|---|
| `get_context()` | none | cwd, wins, mode, lsp_clients, current_file |
| `get_buffers()` | none | all loaded buffers with metadata |
| `get_diagnostics(args?)` | `{bufnr?, severity?}` or nil | severity: 1=Error 2=Warn 3=Info 4=Hint |
| `open_file(args)` | `"path:line:col"` or `[path, line?, col?]` | opens in editor window (not terminal) |
| `exec_lua(code)` | string | execute arbitrary lua, return result |
| `notify(args)` | string or `[msg, level?]` | level: 0=TRACE..4=ERROR, default INFO |
| `spawn_cli(args)` | `{cmd, mode?, name?}` or string | spawn any CLI in nvim terminal, see below |
| `get_terminal_output(args)` | `{bufnr?, name?, tail?}` | read terminal buffer content |
| `list_terminals()` | none | list all spawned terminals and status |
| `send_to_terminal(args)` | `{bufnr?, name?, text}` | send text input to a terminal |

## spawn_cli — Spawn any CLI tool in nvim

Opens a terminal in nvim running any command. The `cmd` is the full shell command — you control everything.

```bash
# Spawn claude in a new tab
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").spawn_cli({cmd=\"claude\", mode=\"t\", name=\"review\"})")'

# Spawn gemini in vsplit
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").spawn_cli({cmd=\"gemini\", mode=\"v\", name=\"gemini1\"})")'

# Spawn codex in float
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").spawn_cli({cmd=\"codex\", mode=\"f\"})")'
```

Parameters:
- `cmd`: full shell command string — any CLI tool, with any flags
- `mode`: `"t"`=tab (default), `"v"`=vsplit, `"h"`=hsplit, `"f"`=float
- `name`: optional label for tracking (used by get_terminal_output/send_to_terminal)

Returns: `{name, bufnr, job_id, mode}`

## Reading terminal output

After spawning a CLI, read its output:

```bash
# Read all output by name
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").get_terminal_output({name=\"review\"})")'

# Read last 50 lines by bufnr
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").get_terminal_output({bufnr=5, tail=50})")'
```

Returns: `{bufnr, lines[], line_count, alive, exit_code}`

## Sending input to terminal

```bash
nvim --server "$SOCK" --remote-expr 'luaeval("require(\"core.agent_api\").exec_lua(_A)", "return require(\"core.agent_api\").send_to_terminal({name=\"review\", text=\"help me review this PR\\n\"})")'
```

## CLI tools reference

For claude with specific API config, prefix env vars in cmd:

```bash
# Claude with API1 config
cmd = "ANTHROPIC_BASE_URL=xxx ANTHROPIC_AUTH_TOKEN=xxx claude --model sonnet"
```

Common interactive flags (do NOT use -p, it's non-interactive):

| CLI | Interactive flags | Notes |
|---|---|---|
| `claude` | `--model <model>`, `--system-prompt "..."`, `--allowedTools "..."`, `--permission-mode <mode>`, `--dangerously-skip-permissions`, `-c` (continue), `-r` (resume) | |
| `gemini` | `-m <model>`, `-y` (auto-approve all), `--approval-mode <mode>`, `-i "prompt"` (interactive with initial prompt) | `-i` sends prompt then stays interactive |
| `codex` | `-m <model>`, `-s <sandbox>`, `-a <approval>` | sandbox: read-only, workspace-write, danger-full-access |

## Observability

Every API call is logged to `$NVIM_AGENT_LOG_FILE`:

```bash
tail -f "$NVIM_AGENT_LOG_FILE"
# format: timestamp \t event=agent_api \t func=xxx \t ok=true/false \t args=...
```
