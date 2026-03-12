# ACP 频道系统 — 问题清单

## P1 尾巴

### #1 推送稳定性
_push_to_main 并发问题，主 Claude 收到 @main 推送有时不回复。
状态：测试中

### #2 统一命名
子 agent system prompt 用 @主agent，路由只识别 @main，需统一。
状态：待修

## 多 adapter 支持

### #3 Gemini adapter 跑不通
gemini CLI 启动后立即退出。get_env 返回空，可能是认证或 ACP 握手问题。
状态：待排查

### #4 Codex adapter 缺失
adapter.lua 里没有 codex，需新增。
状态：待开发

## UX

### #5 频道不可随意关闭
需要防止 agent 或误操作关掉频道 buffer。
状态：待修

### #6 Chat/频道双 buffer 打开体验差
chat UI 和频道 UI 是两个 buffer，有时只能打开一个，切换不顺。
状态：待改进

## Skill 问题

### #7 acp-bus-dispatch 轮询问题
使用 acp-bus-dispatch skill 时，主 Claude 下发任务后会一直轮询访问子 agent 结果。已有主动推送机制（子 agent @main 回频道），不应该再轮询。skill 应该下发任务后等推送通知，而不是 poll。
状态：待修

## 多账号支持

### #8 启动时指定 Claude 命令
**问题**：单个 CC 账号额度用完后频道无法工作。
**需求**：启动 acpchat 或调度子 agent 时，能指定用哪个命令（claude / c1 / c2）。
**现状**：~/.zshrc 已有 c1/c2 alias，adapter.lua 目前写死用 claude 命令。
状态：待设计（低优先级）
