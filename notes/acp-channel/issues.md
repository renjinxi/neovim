# ACP 频道系统 — 问题清单

最后更新：2026-03-13

---

## 已解决 ✅

| # | 问题 | 修复内容 |
|---|------|---------|
| #2 | 统一命名 @主agent→@main | bus.lua 路由 + system prompt 统一 |
| #4 | Codex adapter 缺失 | 已加，但当前版本不支持 ACP，已注释禁用 |
| #5 | 频道 buffer 被误关 | q 改为 hide()，BufWipeout+VimLeavePre 自动清理进程 |
| #6 | Chat/频道双 buffer 体验差 | AcpToggle(<leader>ait)、AcpAgents picker(<leader>aia)、show() 修复 split 顺序 |
| #7 | skill 轮询问题 | 隐藏 bus_agents/bus_read，加推送机制说明 |
| #8 | 多账号支持 | c1/c2 adapter，读 CLAUDE_API1_*/CLAUDE_API2_* |
| #9 | 主 Claude chat 割裂 | _push_to_main 在主 chat buffer 写"← 频道"标记 |
| #10 | 频道消息无时间感知 | _render_message 加时间戳 + 间隔（+Xs） |
| #11 | 通信延迟无法分析 | 新增 logs/acp-client.log，记录握手/prompt/terminal 耗时 |

---

## 进行中 🔧

### #3 Gemini 不回消息
**根本原因**：ACP 握手缺少 authenticate 步骤。gemini 握手流程是：
`initialize → authenticate → session/new`，我们之前跳过了 authenticate。

**已修**：
- client.lua 补全 authenticate 步骤
- adapter: args 改为 `--acp`（`--experimental-acp` 已 deprecated）
- adapter: auth_method 改为 `LOGIN_WITH_GOOGLE`（用本地 OAuth 凭证，不需要 API key）

**进展**：
- authenticate 失败原因找到：methodId 传的是枚举名 `LOGIN_WITH_GOOGLE`，实际值应该是 `oauth-personal`
- 已修改 adapter.lua，改为 `auth_method = "oauth-personal"`
- 待验证：重启 nvim 后测试 `:AcpChat gemini`

---

## 待处理 ⏳

### #1 推送稳定性
`_push_to_main` 并发问题，多个 agent 同时 @main 可能乱序或丢失。
**状态**：未复现，暂跳过。

### #4 Codex ACP 支持
当前 codex 0.114.x 没有 `codex-acp` 命令，ACP 未实现。
**状态**：等官方支持，目前用 ai-task-dispatch PTY 方案代替。

---

## 功能路线图

### P3：子 agent 自主扩展（未开始）
子 agent 能通过 bash 调 RPC 创建新 agent，动态加入频道。
- [ ] rpc.lua 加 bus_add_agent 接口
- [ ] 子 agent system prompt 加 spawn 指令
- [ ] 动态加入后自动注入 system prompt

### P4：频道树（未开始）
频道可以嵌套，子频道独立运行后汇报给父频道。
