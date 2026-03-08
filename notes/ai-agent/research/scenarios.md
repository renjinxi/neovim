# AI-to-AI 协作：场景和模式

## 场景一：MCP 邮件通信（结构化协调）

适合：多个 AI 各自独立干活，通过消息交换结果。

```
主 Claude                          子 AI (便宜的，操作浏览器)
    │                              │
    │ spawn_cli 起子 AI             │
    │ send_message: "去验证这个页面" │
    │──────────────────────────────→│
    │                              │ fetch_inbox → 收到 → 开始干
    │  继续干别的活                  │ 操作浏览器...
    │                              │ 验证完了
    │                              │ send_message: "按钮报错xxx"
    │←──────────────────────────────│
    │ fetch_inbox → 收到结果        │
    │ send_message: "清 cookie 再试"│
    │──────────────────────────────→│
    │                              │ fetch_inbox → 继续干
```

特点：
- 通信结构化（MCP tool 调用）
- 消息不会丢（存 SQLite）
- 有延迟（turn 之间才检查）
- 人随时切 tab 介入

## 场景二：模拟人类输入（AI 扮演人）

适合：主 AI 指挥子 AI，子 AI 无需知道对面是 AI。

```
主 Claude                          子 Claude
    │                              │
    │ spawn_cli 起子 Claude         │
    │ send_to_terminal:            │
    │   "帮我 review init.lua\n"   │
    │──────────────────────────────→│ 以为是人在说话，正常干活
    │                              │ ...review 完了，输出结果
    │ get_terminal_output 读结果    │
    │                              │
    │ send_to_terminal:            │
    │   "这里改一下 xxx\n"          │
    │──────────────────────────────→│ 继续干
```

特点：
- 不需要 mcp_agent_mail，用现有 agent_api 就行
- 子 AI 完全无感知，和人交互一模一样
- 简单粗暴，但通信不结构化（读 terminal 输出）
- 人切 tab 过去可以直接接管

## 场景三：主循环编排（agent loop）

适合：一个主 AI 管理多个子 AI，自动协调，遇到问题问人。

```
主 Claude 的工作循环（纯 system prompt 驱动）：

while 任务没完成:
    1. 检查各子 AI 状态
       - get_terminal_output 看输出
       - fetch_inbox 看消息
    2. 有结果 → 读取，做决策
    3. 需要新任务 → spawn_cli 起新子 AI
    4. 需要指令 → send_to_terminal 给子 AI 打字
    5. 遇到不确定的 → 停下来问人
    6. 人回复 → 继续循环
```

特点：
- 不需要写代码，system prompt 驱动
- 主 AI 扮演"项目经理"角色
- 人只在关键决策点介入
- 可以混用场景一和场景二的通信方式

## 两种通信方式可以混用

| 方式 | 用 agent_api | 用 mcp_agent_mail |
|------|---|---|
| 起子 AI | spawn_cli ✅ | — |
| 简单指令 | send_to_terminal ✅ | — |
| 读输出 | get_terminal_output ✅ | — |
| 结构化消息 | — | send_message ✅ |
| 任务结果 | — | send_message + thread_id ✅ |
| 文件冲突 | — | file_reservation ✅ |

简单场景用 send_to_terminal 模拟人打字，复杂协调用 mcp_agent_mail 结构化通信。

## 待验证

- [ ] system prompt 能否可靠驱动主循环（AI 会不会忘记检查消息）
- [ ] 多个子 AI 并行时的协调效果
- [ ] send_to_terminal 模拟人打字的可靠性（子 AI 会不会困惑）
- [ ] mcp_agent_mail 的实际延迟和稳定性
- [ ] 主 AI 的 context window 够不够管理多个子 AI 的状态
