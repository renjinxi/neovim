# Codex1 对 ACP 多 Agent 系统的想法

by codex1 | 2026-03-15

---

## 我对当前架构的理解

这套 ACP 现在已经有了三个清晰层次：

1. `client.lua`
负责 ACP 协议握手、JSON-RPC、fs/terminal 反向调用和进程生命周期。

2. `chat.lua`
负责单 agent 的 UI、输入、流式渲染和把 session/update 转成可见状态。

3. `bus.lua`
负责多 agent 路由、频道展示、main 队列、会话日志和 agent 编排。

这个拆分方向是对的。它已经不是“聊天 UI”，而是一个轻量的 agent runtime + 协作总线。下一步值得做的，不只是修 bug，而是把“频道”从一个消息面板，升级成一个可管理、可观测、可恢复的协作系统。

---

## 1. 基于现有架构，还可以做哪些设计

### 1.1 从“消息路由”升级成“任务路由”

现在 bus 路由的最小单位还是文本消息，`@agent` 只是一个 mention。这个模式简单，但很快会遇到几个问题：

- 消息和任务没有区别，难追踪
- 没有完成态、失败态、重试态
- 长链路协作时，频道容易退化成刷屏日志

建议引入一个很轻的任务对象，而不是一上来做复杂 workflow：

```lua
{
  task_id = "t-001",
  title = "分析 acp 风险",
  owner = "claude2",
  requester = "main",
  status = "queued|running|blocked|done|failed",
  assignees = {"claude2"},
  artifacts = {"notes/.../claude2-risk-analysis.md"},
  reply_to = "main",
}
```

然后频道保留消息流，但消息只是 task 的事件。

收益：

- UI 可以显示“谁在做什么”而不只是“谁说了什么”
- main 可以看到 pending/running/done 队列
- 恢复时能恢复任务状态，而不只是恢复聊天历史
- 后续做自动重试、超时、仲裁都更顺

这会比继续堆 message-level patch 更稳。

### 1.2 增加 coordinator/planner 角色，而不是让 main 承担一切

当前 `main` 既是默认收件人，也是唯一串行队列入口，还兼任最终裁决者。这会让 `main` 很快变成瓶颈。

建议把角色拆开：

- `main`: 面向用户的主对话 agent
- `planner`: 负责拆任务、指派、聚合结果
- `worker-*`: 负责具体执行
- `critic`: 负责 review / challenge / 风险扫描

这不一定需要 4 个长期进程。可以先做“逻辑角色”，由同一种 adapter 启多个实例。

核心意义是：把“用户对话”和“协作编排”从一个 agent 身上拆开。这样 main 不会既要想事又要收件还要仲裁。

### 1.3 引入可观测性面板，而不只是 winbar 状态

现有 winbar 的 `idle/streaming/activity` 已经很有价值，但还停留在“瞬时状态”。

建议做一个 `:Acp inspect` 或专门 buffer，展示：

- agent 当前状态
- 当前 task / 最近一次 task
- prompt 开始时间、运行时长
- main 队列长度
- terminal 子进程数
- 最近错误
- 最后一个 artifact 路径

这对多 agent 比单纯日志更重要，因为系统问题通常不是“失败了”，而是“卡在哪里、不知道谁卡住、为什么没人接球”。

### 1.4 把 artifact 变成一等公民

你们已经约定“长内容写 `notes/acp-bus/{channel_id}`”，这是对的。但现在 artifact 还是靠 prompt 约定，不是系统结构。

建议 bus 层加 artifact registry：

- agent 回报文件路径时自动登记
- 频道里可列出“本轮产物”
- task 能直接引用 artifact
- 恢复会话时能看见各 task 对应的输出文件

甚至可以约定简单格式：

`ARTIFACT: notes/acp-bus/.../foo.md`

bus 自动解析并挂到 task 或 agent 状态上。这样比靠人眼翻频道稳定很多。

### 1.5 从“恢复聊天”升级成“恢复工作流”

目前 snapshot 只保存历史消息和 agent 名单，恢复后 agent 实际是新 session。这个行为本身没错，但命名上会误导用户。

有两个可选方向：

1. 保守路线
明确把当前能力命名为“重建频道现场”，不要叫“恢复会话”。

2. 进阶路线
在恢复时额外重放必要上下文：
- 频道规则
- 每个 agent 的最近 task
- 最后产出的 artifact 路径
- 一段自动生成的 resume brief

我更推荐第二种。即便 ACP 原生不支持 `session/load`，也可以在应用层做“语义恢复”。这比空起新 agent 但 buffer 看起来像延续，认知上更一致。

### 1.6 增加协作控制原语，而不是全靠自然语言

现在 agent 之间通信全靠 prompt 文本约束。这个方式灵活，但边界弱。

建议加几个 RPC / bus 原语：

- `bus_add_agent(name, adapter, role)`
- `bus_assign(task_spec)`
- `bus_reply(task_id, summary, artifact?)`
- `bus_block(task_id, reason)`
- `bus_done(task_id, result)`
- `bus_abort(task_id)`

不是为了替代自然语言，而是为了给协作骨架加结构。这样可以降低 prompt 偶然性，也更容易做 UI。

### 1.7 把系统 prompt 做成模板化、角色化、能力化

现在 `adapter.get_bus_system_prompt()` 只注入通信规则，保持极简是对的。但随着 agent 类型增加，建议拆成三层：

- 公共频道协议
- 角色协议
- 任务协议

例如：

- 公共频道协议：怎么发消息、怎么写文件、消息长度限制
- 角色协议：planner / worker / critic 各自职责
- 任务协议：当前任务目标、边界、交付格式

这样你们不需要在启动消息里每次重新堆一大段说明，prompt 也更容易稳定。

### 1.8 把安全策略从 adapter 静态配置移到策略层

Claude adapter 默认 `--yolo`，这对实验很快，但从系统设计上有点“能力开到最大，边界靠提示词”。

建议引入 policy 层，决定：

- 哪类 agent 可以开 terminal
- 哪些目录可写
- 哪些 agent 只读
- 是否允许 spawn 新 agent
- 是否允许执行外部命令

也就是把“工具权限”从“模型能力”里抽出来。这对多 agent 特别关键，因为协作系统最怕的是某个 agent 被误导后拿到过大的执行面。

### 1.9 支持仲裁模式，而不只是汇报模式

多 agent 的价值不只在并行，还在分歧。

建议支持一个简单模式：

- main 提一个问题
- 两个 agent 独立产出
- critic 比较两者
- planner 给出最终建议

这个模式特别适合：

- 架构方案对比
- 风险评审
- patch review
- 根因分析

这会比现在“一个做分析，一个回 main”更能发挥多模型差异。

### 1.10 增加测试/回放机制

ACP 现在很多问题其实是“时序 + 交互”问题，单看代码难完全覆盖。

建议补一个 transcript replay / scenario runner：

- 给定一组频道消息
- 模拟 agent 上下线、超时、错误
- 校验 bus 最终状态和渲染输出

不需要一开始就做端到端真 agent，可以先做 fake client。否则后续每改一次路由和恢复逻辑，都容易引入新竞态。

---

## 2. 从 Codex 视角，这套多 agent 协作还能怎样更好用

### 2.1 最重要的是减少“语言协议”的负担

对我这种偏执行型 agent 来说，最容易出问题的不是工具使用，而是协作协议过度依赖自然语言约定。

例如现在我需要自己记住：

- 默认收件人是 `@main`
- 频道消息 50 字以内
- 长内容要写到指定目录
- 每个任务只回复一次

这些规则是可行的，但它们是软约束。更好用的方式是：

- 短消息与长消息分成两个明确接口
- artifact 通过显式 API 上报
- “一次回复”由任务状态机约束，而不是靠提示词提醒

也就是说，多 agent 想稳定，不应过度依赖模型记住频道 etiquette，而应让系统把 etiquette 固化成接口。

### 2.2 给 agent 一个“收件箱视图”会比纯频道更高效

频道很适合人看全局，但 agent 本身更适合处理“分配给我的事项”。

建议给每个 agent 一个 inbox 抽象：

- 待处理任务
- 最近上下文
- 需要回复给谁
- 输出格式要求

对 agent 来说，这比不断从长频道历史里提取“下一步我要做什么”更稳定，也更省 token。

### 2.3 支持“只读 agent”和“执行 agent”分工

Codex 很适合做代码浏览、差异分析、风险枚举、补丁生成、测试建议。但不是每个子任务都需要 shell / fs 写权限。

建议把 agent 分成：

- `reader/reviewer`
- `editor`
- `runner`

这样系统可以把不同类型任务派给不同能力边界的 agent，既安全，也更接近实际工程分工。

### 2.4 让 agent 能声明“不确定度”和“需要什么上下文”

多 agent 协作里，一个高频低效点是：agent 其实没足够上下文，但还是先回了一版。

建议支持标准化状态：

- `blocked: missing file`
- `blocked: unclear owner`
- `needs_context: foo/bar.lua`
- `confidence: low|medium|high`

这会比单纯回一段自然语言更利于 orchestration。planner 或 main 可以据此决定补材料、换 agent、还是直接终止。

### 2.5 允许 agent 主动请求“压缩上下文”

长时间频道协作后，上下文会脏。对于 Codex 这类执行型 agent，一个很实用的能力是：

- 请求生成本轮摘要
- 请求把某个 artifact 设为 canonical brief
- 之后只基于 brief + 少量增量继续

如果 ACP 原生未来支持 compact/clear，一定值得在 UI 层暴露。多 agent 比单 chat 更早撞到上下文膨胀问题。

### 2.6 让产出格式更机器可读

如果系统希望真正做协作，而不是“多个人工聊天窗口”，产出最好不止是 prose。

建议允许 agent 回复结构化头部，例如：

```text
STATUS: done
SUMMARY: 已完成风险分析
ARTIFACT: notes/acp-bus/.../risk.md
FOLLOWUP: @main 决定是否实现超时队列
```

bus 可以解析，UI 也可以展示，而 agent 仍然可以在 artifact 里写自由文本。这会明显降低 orchestration 成本。

---

## 3. 我看到的、Claude 可能遗漏的盲点

Claude2 的风险分析已经覆盖了很多重要点，尤其是循环路由、恢复错觉、main 队列阻塞。这些判断基本成立。下面是我觉得它没有充分展开的地方。

### 3.1 当前系统还没有真正的“身份边界”

bus 里 `from` 本质上是一个字符串，`bus_post_file(from, path)` 也默认信任传入者身份。也就是说，系统里的“身份”现在是约定，不是校验。

短期内这没问题，因为所有 agent 都是你自己起的。但一旦后续支持：

- agent 自主 spawn agent
- 外部脚本发消息
- 不同 adapter 混合接入

就会出现身份冒充和消息伪造问题。至少应该逐步考虑：

- agent token / nonce
- 仅允许已注册 agent 发言
- `from` 和已知 session 的绑定

这不是安全洁癖，而是协作系统一旦规模变大，身份和路由是同一件事。

### 3.2 系统目前没有“背压”机制

你们已经有 main 串行队列，但没有系统级背压策略。问题不只是 main 卡住，而是：

- 频道里短时间进来 20 条任务怎么办
- 某个 agent 连续被 @10 次怎么办
- artifact 写入过多怎么办
- terminal 子进程暴涨怎么办

也就是系统没有 admission control。建议加：

- 每 agent 最大排队数
- 全局最大并发数
- 超出后直接回 `busy`
- 队列老化 / 丢弃策略

Claude 提到了 timeout，但没提到背压。这两者不是一回事。

### 3.3 “频道即真实状态”会逐渐失真

现在用户看到的核心是频道 buffer，但真实状态已经分散在：

- `messages`
- `agents`
- `chat` 内 streaming 状态
- session log 文件
- artifact 文件
- main chat buffer

当系统继续长大后，频道一定会和真实工作状态脱节。这个问题不是 UI 小修能解决的，需要明确：

- 频道是事件流
- task board 是状态面
- artifact list 是结果面

Claude 的分析更偏“频道还能怎么稳”，但没触及“频道不应该承担所有语义”这个架构点。

### 3.4 现有架构对“模型差异”利用得还不够

现在不同 adapter 更多是接入差异，不是能力编排差异。

但实际上：

- Claude 更适合长推理和代码阅读
- Codex 更适合执行、补丁、验证
- Gemini 可能更适合某些快速草稿/多样化思路

系统如果只把它们都当成“会回消息的 agent”，会浪费多模型价值。建议显式给 adapter 标注 traits：

- `strengths = {"review", "implementation", "planning"}`
- `cost_class`
- `latency_class`
- `tooling = {"terminal", "fs-write"}`

然后 planner 或 main 可以按任务类型派单，而不是只按名字 `@codex1`、`@claude2`。

### 3.5 缺少“结果验收”闭环

现在 worker 把分析写完，发个简短消息，流程就结束了。但系统没有验收层：

- 谁确认完成
- 如何判断 artifact 满足要求
- 是否需要 second opinion
- 是否要自动进入下一步

这会让多 agent 协作停留在“并行外包”，而不是“可控流程”。建议最少加一个 `accepted/rejected` 概念，哪怕先只在 task 层做。

### 3.6 对失败类型的建模还太粗

当前大多是 `disconnected/error/cancelled`。但多 agent 系统里更有价值的是区分：

- transport failure
- tool failure
- model refusal
- context missing
- timeout
- policy denied
- conflicting edits

因为这些失败对应的恢复动作完全不同。Claude 关注了“失败后没反馈”，但没继续往“失败分类”走。

---

## 我会优先做的三件事

如果只做三件事，我建议是：

1. 引入轻量 task 层
让频道从纯消息流变成“消息 + 任务事件”。

2. 引入结构化协作原语
至少有 assign / done / blocked / artifact 四个动作，减少纯自然语言协议负担。

3. 做一个 inspect/task board 视图
把真实状态从频道里解耦出来，不然后面功能越多，频道越像日志垃圾桶。

---

## 总结

这套 ACP 已经不只是“Neovim 里开几个 AI 聊天窗”，而是在往一个 IDE 内部的 agent coordination runtime 走。当前代码里最值钱的部分，其实不是 UI，而是：

- agent 生命周期管理
- ACP 反向能力承接
- bus 作为协作总线的雏形

下一阶段最值得补的不是更多命令，而是三件事：

- 结构化任务
- 明确状态面
- 系统级协作原语

如果这三件事立住，多 agent 才会从“有趣 demo”变成“可长期使用的工程工具”。
