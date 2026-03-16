# Neovim + ACP: Multi-AI Agent Collaboration in Your Editor

![Neovim](https://img.shields.io/badge/Neovim-0.11+-57A143?logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-2C2D72?logo=lua&logoColor=white)
![ACP](https://img.shields.io/badge/ACP-Agent_Communication_Protocol-blue)
![Multi-Agent](https://img.shields.io/badge/Multi--Agent-Claude_%7C_Codex_%7C_Gemini-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active_Development-brightgreen)

> **What if multiple AI agents could collaborate inside your editor — and you could watch, intervene, and steer them in real time?**

This is a Neovim configuration with a built-in **ACP (Agent Communication Protocol) channel system** that enables multiple AI agents (Claude, Codex, Gemini) to work together in shared message channels. You sit in front of Neovim, your main agent assists you, and sub-agents are dispatched to do the work. The channel is the visible layer — humans can jump in anytime.

## How It Works

```
You (in Neovim)
  │
  └── Main Agent (AcpChat)
        │
        ▼
      Channel
        ├── agent-1 (claude)   ── review code
        ├── agent-2 (codex)    ── implement feature
        └── agent-N (gemini)   ── research docs
```

Agents communicate through **shared channels** with `@mention` routing. Messages flow through the channel — you see everything, and can send messages to any agent directly.

## Key Features

- **Multi-adapter support** — Claude, Codex, Gemini via ACP protocol (JSON-RPC 2.0)
- **Channel-based collaboration** — shared message space with @mention routing
- **Human-in-the-loop** — observe, intervene, and direct agents in real time
- **Chat UI** — standalone 1v1 conversation windows linked to channels
- **Observability** — agent status winbar, Telescope picker, per-agent chat buffers
- **Command system** — `/add`, `/stop`, `/list`, `/open`, `/pick`, `/status`, `/cancel`, `/exit`, `/leave`
- **Persistence** — channel snapshot save/restore
- **Auto file-off** — long messages (>300 chars) auto-saved to files, channel shows summary
- **Health monitoring** — dual-channel status detection (ACP + RPC callback), streaming timeout warnings

## Roadmap

| Milestone | Description | Status |
|-----------|-------------|--------|
| M0 | Basic communication — protocol layer, single agent chat | ✅ Done |
| M1 | Channel collaboration — multi-agent, @mention routing, architecture redesign | ✅ Done |
| M2 | Task layer — task objects, structured collaboration primitives, inspect panel | Design |
| M3 | Self-expansion — sub-agents can spawn new agents | Planned |
| M4 | Channel tree — nested channels, child reports to parent | Planned |
| M5 | Remote agents — HTTP/WebSocket transport | Planned |

## Quick Start

```vim
" Open a chat with Claude
:Acp chat claude

" Open a channel and add agents
:Acp open
/add claude reviewer
/add codex implementer

" Send a message to a specific agent
" (type in the channel input, use @name to route)

" Telescope agent picker
:Acp pick

" Agent leaves channel
:Acp leave reviewer
```

## Architecture (17 modules)

```
lua/acp/
├── init.lua          # Public API + :Acp commands
├── channel.lua       # Channel core — messages, agent mgmt, routing
├── channel_view.lua  # Channel UI — buffer rendering, winbar, input
├── bus.lua           # Channel facade (backward compat)
├── router.lua        # @mention routing
├── scheduler.lua     # Agent scheduling + main push queue
├── task.lua          # Task data model
├── agent.lua         # Agent data structure
├── registry.lua      # Global channel registry
├── chat.lua          # 1v1 Chat UI
├── client.lua        # ACP protocol client (handshake/prompt/stream)
├── jsonrpc.lua       # JSON-RPC 2.0 codec
├── adapter.lua       # Adapter configs (claude/gemini/codex)
├── commands.lua      # Input command system
├── picker.lua        # Telescope agent picker
├── rpc.lua           # Neovim RPC entry (for external processes)
└── store.lua         # Channel persistence
```

## Documentation

- Issue tracker: [`notes/acp-channel/issues.md`](notes/acp-channel/issues.md)
- Roadmap: [`notes/acp-channel/roadmap.md`](notes/acp-channel/roadmap.md)
- Architecture design: [`notes/acp-channel/design/`](notes/acp-channel/design/)
- Research notes: [`notes/acp-channel/research/`](notes/acp-channel/research/)

## Neovim Config

Beyond ACP, this is a full-featured Neovim setup with 90+ plugins (Lazy.nvim), supporting both native Neovim and VSCode/Cursor.

- **LSP** — 15+ language servers via Mason
- **Completion** — nvim-cmp + luasnip
- **Debugging** — nvim-dap (Python/C++/Go/JS)
- **Navigation** — Telescope + Flash + nvim-tree
- **Git** — Neogit + LazyGit + gitsigns + diffview
- **UI** — Rose Pine + Heirline statusline

```
lua/
├── core/           # Base config (options/autocmds/env)
├── plugins/        # Plugin ecosystem (specs, configs, keymaps, dap)
├── acp/            # ACP channel system (see above)
└── user/           # User customizations
```

## Contributing

This project is in active development. If you're interested in multi-AI agent collaboration within editors, feel free to open an issue or reach out.
