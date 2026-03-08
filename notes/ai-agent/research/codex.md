# Unlocking the Codex harness: how we built the App Server

来源: https://openai.com/index/unlocking-the-codex-harness/
作者: Celia Chen
发布日期: 2026-02-04

## 一句话总结

这篇文章讲的是：OpenAI 为了让 `Codex` 能同时跑在 `CLI`、`VS Code 扩展`、`Web`、`macOS App` 等不同产品形态里，没有让每个客户端各自实现一套 agent 逻辑，而是把通用 agent 能力收敛成一个统一的运行时 `Codex harness`，再通过一个双向的 `JSON-RPC` 服务层 `Codex App Server` 暴露给不同客户端使用。

换句话说，`App Server` 是各类 Codex 前端界面和底层 agent runtime 之间的标准桥梁。

## 文章核心观点

作者想表达的重点不是“Codex 会写代码”，而是：

1. `Codex` 的关键价值不只在模型本身，还在于承载 agent 工作流的 runtime。
2. 当一个 agent 需要在多个产品界面里复用时，简单的 request/response API 不够用。
3. 真正可用的 agent 平台，需要处理：
   - 长生命周期会话
   - 增量流式输出
   - 工具调用
   - 用户审批
   - 历史持久化
   - 向后兼容的协议演进
4. OpenAI 把这些都落在了 `Codex App Server` 里。

## 为什么要做 App Server

最开始，OpenAI 只是想复用已经写好的 `Codex CLI` agent loop。

### 最初场景

- `Codex CLI` 先出现，它本质上是一个 `TUI` 里的 coding agent。
- 后来 OpenAI 做 `VS Code` 扩展时，希望扩展里也能复用同一套 agent 行为，而不是重新实现一套。

### 复用时遇到的问题

IDE 场景比终端复杂得多，客户端需要的不只是“发一个 prompt，拿一个回答”，还需要：

- 浏览 workspace
- 展示 agent 推理中的进度
- 展示差异 diff
- 接收工具执行事件
- 在需要时弹审批框

OpenAI 一开始试过把 Codex 暴露成 `MCP server`，但发现如果要让它很好地适配 VS Code 这类 IDE，`MCP` 语义维护起来比较困难。于是他们改成设计一套更贴近 Codex agent loop 的 `JSON-RPC` 协议。

这个协议后来逐渐演变成 `Codex App Server` 的早期版本。

### 为什么后来要把它做成正式平台

随着 Codex 被更多内部团队和外部伙伴使用，越来越多产品都想接同一套能力：

- `JetBrains`
- `Xcode`
- `Codex desktop app`
- 其他需要把 Codex 嵌进产品的伙伴

这时，App Server 不能再只是“内部能跑就行”的私有接口，而必须变成：

- 可集成
- 稳定
- 可演进
- 向后兼容

也就是从“为了复用 CLI 代码做的适配层”，升级成“统一的 agent 平台接口”。

## Codex harness 里面到底有什么

文章强调：`agent loop` 只是 Codex harness 的一部分，不是全部。

完整的 Codex harness 至少包含三类能力。

### 1. Thread 生命周期和持久化

`Thread` 可以理解成一个长期存在的 Codex 会话。系统需要支持：

- 创建 thread
- 恢复 thread
- fork thread
- 归档 thread
- 持久化 event history

为什么这很重要：

- 客户端断开后还能重连
- 不同 UI 能渲染同一条历史时间线
- 会话可以跨设备、跨界面延续

### 2. 配置和鉴权

Codex 不只是一个推理引擎，还要处理很多产品层能力：

- 读取配置
- 管理默认值
- 处理登录流，比如 `Sign in with ChatGPT`
- 维护 credential state

这意味着客户端不需要自己重新发明这些通用机制。

### 3. 工具执行和扩展机制

Codex 需要在沙箱里执行工具，并把扩展能力纳入统一策略模型，包括：

- shell/file 工具
- MCP servers
- skills

这里的重点是：工具不是零散外挂，而是被纳入一个一致的 agent 执行框架和权限模型里。

## Codex core 和 App Server 的关系

文章中提到 `Codex core` 是 `Codex CLI` 代码库中的一部分。

它有两层身份：

1. 一个库
2. 一个 runtime

作为库，它承载所有 agent 代码。
作为 runtime，它可以被启动起来，管理一个具体 thread 的 agent loop 和持久化。

但 `Codex core` 本身还不是面向客户端直接使用的接口。

客户端真正接入的是 `Codex App Server`。

## App Server 的定位

`Codex App Server` 同时指两件事：

1. 客户端和服务端之间使用的那套 `JSON-RPC` 协议
2. 承载 `Codex core threads` 的长生命周期进程

也就是说，它既是协议规范，也是运行中的 server 进程。

## App Server 进程内部结构

文章给出的结构可以概括成四个核心组件：

1. `stdio reader`
2. `Codex message processor`
3. `thread manager`
4. `core threads`

### 各组件职责

#### 1. stdio reader

- 从客户端接收 `JSON-RPC` 消息
- 把输入转发给后续处理层

#### 2. Codex message processor

- 解析客户端请求
- 转换成 `Codex core` 能理解的操作
- 监听 core 的内部事件流
- 再把这些低层事件翻译成稳定的、适合 UI 使用的 `JSON-RPC notifications`

它本质上是协议翻译层。

#### 3. thread manager

- 按 thread 维度管理 session
- 每个 thread 启动一个独立的 core session

#### 4. core threads

- 真正运行 agent loop
- 承载某一个会话上下文
- 输出事件和更新

### 这一层设计的意义

一个客户端请求通常不会只得到一个返回值，而会产生很多细粒度事件：

- 线程开始
- turn 开始
- 用户消息被登记
- 工具执行
- 审批请求
- assistant 流式输出
- turn 完成

正因为中间层把这些“低层运行事件”转成“稳定的 UI 事件”，前端才有办法构建丰富交互，而不用直接耦合到底层 runtime 的内部实现。

## 为什么协议必须是双向的

文章特别强调：`JSON-RPC` 协议是 **fully bidirectional**。

这点非常关键，因为 agent 交互不是普通的单向 API 调用。

普通接口常见模式是：

- 客户端发请求
- 服务端回结果

但 agent 不是这样。Codex 在执行过程中可能会：

- 连续推送进度
- 流式输出文本
- 发出工具调用事件
- 主动向客户端请求审批
- 等待客户端回复后再继续执行

因此，服务端不仅要“响应”，还要能“主动发 request”。

这也是作者为什么强调它不是简单的 request/response API。

## 对话协议的三个核心原语

文章把整个协议抽象成三层 primitive：

1. `Item`
2. `Turn`
3. `Thread`

这是整篇文章最关键的建模部分。

### 1. Item

`Item` 是 Codex 输入/输出的原子单元。

它可以是不同类型，例如：

- 用户消息
- agent 消息
- 工具执行
- 审批请求
- diff

每个 item 都有明确生命周期：

- `item/started`
- 可选的 `item/*/delta`
- `item/completed`

#### 这个生命周期为什么重要

因为它天然适合 UI 渲染：

- `started` 一到，UI 就能先创建占位卡片
- `delta` 来了，UI 就能流式追加内容
- `completed` 到达后，UI 再把最终状态定格

这相当于把“流式内容”和“终态结果”统一到一个事件模型里。

### 2. Turn

`Turn` 是一次由用户输入触发的 agent 工作单元。

例如用户说：

`run tests and summarize failures`

从这一刻开始，到 agent 产出完整结果为止，这一整段工作就是一个 turn。

一个 turn 内部会包含多个 item，例如：

- 用户输入 item
- command execution item
- approval item
- agent message item

### 3. Thread

`Thread` 是一个可持续存在的会话容器。

一个 thread 可以包含多个 turn，并且具备：

- create
- resume
- fork
- archive

此外，thread 历史会被持久化，这样客户端即使重连，也能恢复一条一致的时间线。

### 这三层抽象的价值

这套设计把复杂 agent 交互拆成三层：

- `Item` 负责原子事件
- `Turn` 负责一次任务
- `Thread` 负责长期会话

这样可以让：

- 协议更清晰
- UI 更容易做
- 状态恢复更可靠
- 多端表现保持一致

## 协议流程：初始化握手

在任何正式请求之前，客户端必须先发一次 `initialize`。

文章给的例子里，请求大致是：

```json
{
  "method": "initialize",
  "id": 0,
  "params": {
    "clientInfo": {
      "name": "codex_vscode",
      "title": "Codex VS Code Extension",
      "version": "0.1.0"
    }
  }
}
```

服务端返回的结果里包含 `userAgent`，用于标识服务端环境和客户端信息组合。

### initialize 的作用

- 协商协议版本
- 交换 feature flags
- 确定默认行为
- 让服务端知道客户端是谁

这个设计很像成熟协议里的 capability negotiation。

## 协议流程：thread 和 turn 启动

当客户端发起一次新的请求时，通常先做两件事：

1. 创建 `thread`
2. 启动 `turn`

随后服务端会发通知，例如：

- `thread/started`
- `turn/started`

并把用户输入也作为一个 item 记录下来。

这个处理方式说明了一点：在 App Server 视角里，用户消息并不是一个“附带参数”，而是一个明确可追踪的协议事件。

## 协议流程：工具执行和审批

工具调用也会被建模成 item。

典型流程是：

1. 服务端发 `item/started`
2. 如果动作需要用户许可，服务端发 `item/commandExecution/requestApproval`
3. 客户端回 `allow` 或 `deny`
4. 服务端继续执行，并在结束后发 `item/completed`

文章里举的例子是运行：

```bash
pnpm test
```

### 这里反映出的设计原则

- 审批不是 UI 的私有逻辑，而是协议的一部分
- agent 会因为等待审批而暂停当前 turn
- 客户端回复审批结果后，turn 才继续

这让不同客户端都能用一致方式实现权限交互。

## 协议流程：流式 assistant message

当 agent 生成回复时，不是一次性吐出最终文本，而是按增量流回来。

典型事件序列是：

1. `item/started`
2. `agentMessage/delta`
3. `agentMessage/delta`
4. `item/completed`
5. `turn/completed`

### 这样设计的直接好处

- UI 可以立即显示输出过程
- 用户能看到 agent 在持续工作，而不是卡住
- 移动端、桌面端、IDE 端都能复用同一流式语义

## 如何查看一个完整 turn 的 JSON

文章给了一个调试命令：

```bash
codex debug app-server send-message-v2 "run tests and summarize failures"
```

这个命令的含义是：直接通过调试客户端跑一轮 message 流程，从而观察完整的协议事件 JSON。

## 不同客户端如何接入 App Server

文章接下来介绍了三种主要接入模式：

1. 本地 app / IDE
2. Codex web runtime
3. TUI

虽然你给的页面截取里后半部分没有完全展开，但从前文已经可以看出 OpenAI 的总体思路：

- 不同产品形态可以有完全不同的 UI
- 但都通过同一个协议接入相同的 agent runtime
- 因而能共享 thread、turn、item 语义和工具执行模型

## 从工程角度看，这篇文章真正讲了什么

如果只看表面，这像是一篇“协议介绍”。但从工程设计角度，它讲的是更深一层的东西。

### 1. Agent 产品的真正难点在运行时，不在聊天框

一个能用的 coding agent，并不是接个模型输出文本就够了。

还需要同时处理：

- 会话管理
- 流式消息
- tool use
- 用户审批
- 状态持久化
- UI 兼容
- 权限边界

`App Server` 就是在解决这些运行时问题。

### 2. Agent API 不能套传统 request/response 心智

传统 API 倾向于：

- 单请求
- 单响应
- 一次性结束

但 agent 工作流是：

- 长时运行
- 多阶段事件
- 可能暂停
- 可能等待人类输入
- 中途不断生成产物

所以需要事件驱动、双向通信和显式生命周期。

### 3. 协议设计必须围绕 UI 可渲染性

OpenAI 没有直接把底层内部事件裸暴露给客户端，而是做了一层翻译，把它们变成稳定、适合 UI 的通知。

这说明他们很清楚：

- 底层 runtime 可以持续演化
- 但客户端要依赖稳定事件语义
- UI 一旦耦合内部实现，后续迭代会非常痛苦

### 4. 会话级抽象是多端一致性的基础

`thread -> turn -> item` 这三级模型，是整套系统可扩展的关键。

因为一旦统一了：

- Web
- CLI
- IDE
- Desktop

都能共享一套状态机和历史记录结构。

### 5. 审批机制必须进入协议层

很多 agent 产品把“权限确认”当成前端弹窗逻辑，但 OpenAI 把审批直接建模进协议。

这意味着：

- 审批可追踪
- 审批可暂停 turn
- 审批行为可以跨客户端一致实现
- 安全策略不依赖某一个 UI 的临时实现

## 适合抄走的设计启发

如果自己要做 agent 平台，这篇文章最值得借鉴的是下面这些点。

### 1. 用事件流建模，而不是只设计 REST/单次 RPC

要从一开始就考虑：

- started
- delta
- completed
- pause / resume
- approval request / response

### 2. 把“消息”和“工具调用”统一成 item

这样前端渲染层不用区分太多内部机制，只需要围绕 item 类型渲染不同卡片。

### 3. 把会话长期状态单独抽象成 thread

否则客户端一断线，状态恢复会很痛苦。

### 4. 在 runtime 和 UI 之间增加稳定翻译层

不要让前端直接依赖 agent 内部状态机。

### 5. 把审批作为协议事件，而不是散落在产品逻辑里的弹窗

这样更安全，也更容易跨端复用。

## 可以怎么理解 App Server 的本质

一个简化但比较准确的理解方式是：

`Codex App Server = 面向多客户端的 agent session bus + protocol adapter + runtime host`

拆开理解：

- `session bus`: 承载 thread/turn/item 事件流
- `protocol adapter`: 把 core 内部事件转成稳定 JSON-RPC 语义
- `runtime host`: 真正托管 Codex core 线程和会话

## 文章里的重要术语速记

- `Codex harness`: 承载 agent loop 及相关能力的整体运行时
- `Codex core`: CLI 代码库中的 agent 核心库/运行时
- `App Server`: 面向客户端的双向 JSON-RPC 协议与长生命周期 server 进程
- `Thread`: 长期会话容器
- `Turn`: 一次由用户输入触发的 agent 工作单元
- `Item`: 输入/输出/工具/审批/diff 等原子单元
- `delta`: 流式增量事件
- `approval`: 用户许可流程

## 我的理解总结

这篇文章本质上是在回答一个工程问题：

**“当同一个 coding agent 需要服务多个产品界面时，底层能力应该如何被组织和暴露？”**

OpenAI 给出的答案是：

- 把 agent 核心封装成 `Codex core`
- 用 `App Server` 承载线程与协议
- 用 `thread / turn / item` 抽象完整交互
- 用双向 `JSON-RPC` 支持流式事件和审批回路
- 用稳定通知层隔离 UI 和底层 runtime

所以，这篇文章的价值主要不在“介绍了一个内部组件”，而在于它展示了一个比较成熟的 agent runtime 架构思路，尤其适合做：

- IDE agent
- coding assistant
- SRE/ops agent
- 多端共享的 AI 工作流平台

## 原文中最值得记住的结论

1. `Codex` 各个产品表面不同，但底层共享同一个 harness。
2. `App Server` 是连接客户端和 harness 的关键层。
3. agent 系统需要双向协议，而不是普通单向 API。
4. `item / turn / thread` 是这套系统的核心状态模型。
5. 稳定协议层的意义，是让产品快速扩展到更多客户端而不重写 agent 核心。
