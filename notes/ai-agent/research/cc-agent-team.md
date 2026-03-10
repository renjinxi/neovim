 刚才的 team 已经清理了。你问的是这个通信机制能不能迁移出来单独用 — 让我直接说：

  核心机制其实很简单：

  1. 消息传递 — 基于文件系统。agent 之间的消息写到 ~/.claude/teams/{team}/ 下的 JSON 文件里，接收方轮询读取
  2. 任务协调 — ~/.claude/tasks/{team}/ 下每个任务一个 JSON 文件（1.json, 2.json...），所有 agent 共享读写
  3. agent 隔离 — 每个 agent 跑在独立的 tmux pane 里，本质就是一个独立的 Claude Code CLI 进程
  4. 通信协议 — SendMessage 就是往对方的 mailbox 写 JSON，对方的进程检测到新消息后注入到对话上下文里

  能不能迁移出来？

  不太容易直接复用。这套机制深度绑定在 Claude Code CLI 内部：
  - 消息注入依赖 CLI 的对话管理
  - 权限审批依赖 CLI 的 permission 系统
  - agent 生命周期管理和 tmux 集成是 CLI 特有的

  但如果你想自己搞类似的多 agent 协作：

  - 最简单的方案：用 Claude Agent SDK（claude_agent_sdk），它提供了更干净的 agent 编排 API
  - 或者自己实现：文件系统 mailbox + 多进程 + 共享任务 JSON，原理就这么简单，核心代码量不大

  想深入看哪个方向？Agent SDK 还是自己从零搭？
