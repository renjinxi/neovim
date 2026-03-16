# ACP 频道日志复盘 (2026-03-15 ~ 2026-03-16)

12 个频道会话，46 个日志文件，覆盖 ESOP 开发、MC 架构讨论、ACP 重构、ai-work-os 立项、agent 通信测试等场景。

---

## 一、问题汇总

### P0：agent 并发 prompt 无队列保护（#37）

**现象**：bus-20260316-151732，alice 给 bob 发消息时 bob 的第一个 prompt 还没完成，导致 bob 两次 push_to_agent 都没有 done 回调，之后 bob 持续 streaming 直到进程退出。

**根因**：`push_to_agent` 不检查 agent 是否已在 streaming，直接发第二个 prompt。而 `push_to_main` 有 `_main_busy` 串行队列保护。

**影响**：agent 卡死、兜底不触发、状态永远是 streaming。

**建议**：push_to_agent 加 per-agent 串行队列，和 push_to_main 对称。

### P1：agent 不回复频道（兜底失效的假象）

**现象**：bus-20260315-194626 中 worker 阶段二、三完成后"又没回复频道"。bus-20260315-213734 中 codex "idle 了但没回复"。

**分析**：
- worker 的情况是**重构自身代码**导致运行时状态可能不一致，兜底 pcall 静默失败
- codex 的情况是 codex CLI 不理解 @main 回复指令，输出了文字但没按频道格式走
- 兜底代码（scheduler.lua L196-210）本身逻辑正确，self_posted 检测 + fallback post 都在

**建议**：兜底 post 外层加 pcall + 日志，失败时不静默。

### P2：Gemini 频繁出错

**现象**：
- bus-20260315-174355：charlie (gemini) 执行出错
- bus-20260315-213734：gemini 配额耗尽 (500 Resource exhausted)
- bus-20260315-152955：gemini 无响应后被取消

**分析**：gemini adapter 稳定性最差，认证/配额/响应三个层面都出过问题。

### P3：Codex (c1) 认证失败

**现象**：
- bus-20260315-181904：bob (c1) 认证失败 "401 该..."
- bus-20260315-174355：bob (c1) 执行出错

**分析**：c1 adapter 使用的 API key 可能过期或被限制。codex (原生) 相对稳定。

### P4：进程批量退出

**现象**：bus-20260315-152955 所有 agent (codex/dev/dev2) 同时 code=0 退出。bus-20260315-174355 alice/bob 同时退出。

**分析**：可能是 nvim 退出或频道 close 触发的批量 cleanup。不是 bug，但日志里没有区分"主动关闭"和"异常退出"。

**建议**：close() 时加日志标记 `reason=user_close`，和 on_exit 的异常退出区分。

### P5：消息发给不在线的 agent

**现象**：bus-20260316-151732 bob 退出后系统尝试路由错误消息给 alice，但 alice 也不在线了。bus-20260316-152828 `claude 不在线` 但立即上线。

**分析**：agent 注册和就绪之间有时间差，消息在这个窗口期会丢失。

---

## 二、协作模式观察

### 效果好的模式

**1. 主协调 + 专职 worker（最佳模式）**

bus-20260315-143109 (ESOP)：main 协调，dev 写代码，reviewer 做 code review。
- 流程：main 定义任务 → dev 调研回复确认点 → main 拍板 → dev 实现 → reviewer review → main 转发修复意见 → dev 修复 → reviewer 复查
- 效果极好：01 公告附件从任务分配到 review 通过约 25 分钟
- 关键成功因素：**角色分工清晰**（dev 只写代码，reviewer 只审代码，main 做决策和中转）

**2. 并行探索 + 汇总（适合调研）**

bus-20260316-112859 (ai-work-os)：3 个 agent 并行探索不同方向。
- explorer 盘点资产、architect 提取想法、researcher 看代码
- main 等所有结果回来后综合判断
- 效果好：7 分钟内完成了一个人需要半天的调研

bus-20260315-162601 (MC)：claude 看代码、claude2 看 ACP 架构、codex 分析协议。
- 三路并行 + main 汇总，30 分钟完成完整架构方案

**3. 链式协作（agent-to-agent）**

bus-20260316-151732：alice 写函数 → 发给 bob 写测试。
- 14 秒完成链式传递
- 但 bob 卡死了（P0 并发 prompt 问题），说明链式协作对系统稳定性要求更高

**4. 架构师 + worker + reviewer 三角（重构场景最佳）**

bus-20260315-194626 (ACP #29)：claude1 设计方案 → worker 实现 → claude1/claude2 review → 发现问题 → worker 修复。
- 四阶段重构，每阶段都有设计→实现→review 的完整循环
- 唯一问题是 worker 不回复频道（P1），需要 main 手动检查 git diff

### 效果差的模式

**1. 给不稳定 agent 派关键任务**

bus-20260315-152955：给 gemini 派需求分析，结果无响应被取消。codex 回复了非常高质量的分析，但 gemini 浪费了等待时间。

**2. 多 agent 但任务不够并行**

bus-20260315-174355：同时给 alice/bob/charlie 发"自我介绍"，但 bob 和 charlie 都出错。只有 alice 回了。资源浪费。

**3. 等待不确定的 agent**

bus-20260315-152955 L57：`gemini 还没回复...让我查一下 gemini 的状态...让我再 ping 一下...`。等了 3 分钟最终放弃。应该有超时机制。

---

## 三、Agent 表现对比

| Agent | 稳定性 | 响应速度 | 输出质量 | 频道意识 | 适合场景 |
|-------|--------|---------|---------|---------|---------|
| **claude** | ★★★★★ | 快（5-30s） | 高 | 强（理解 @mention、写文件） | 架构设计、review、调研 |
| **codex** | ★★★★ | 中（10-60s） | 高（尤其协议分析） | 弱（不总是 @main） | 代码分析、协议层、实现 |
| **c1** (claude api1) | ★★★ | 快 | 高 | 强 | 同 claude，但认证偶尔出问题 |
| **c2** (claude api2) | ★★★★ | 快 | 中高 | 强 | 开发实现、不太复杂的任务 |
| **gemini** | ★★ | 慢/超时 | 未充分验证 | 未充分验证 | 目前不可靠，不建议关键路径 |

**关键发现**：
- claude 是唯一在所有场景都表现稳定的 agent
- codex 分析能力突出（bus-20260315-152955 的协议分析比 gemini 好一个级别），但频道意识弱
- gemini 在 12 个频道中出问题 3 次，成功率低于 50%

---

## 四、改进建议

### 系统机制层

1. **push_to_agent 加串行队列**（P0，解决并发 prompt 卡死）
2. **agent 超时机制**：prompt 发出后 N 分钟无响应 → 通知 main + 标记 timeout
3. **兜底 post 加 pcall 保护**：失败不静默，写日志
4. **退出原因区分**：close/cleanup vs 异常退出

### 调度策略层

5. **agent 健康分级**：基于历史成功率自动降级不稳定 agent（如 gemini → 只用于非关键任务）
6. **自动重试**：认证失败 → 自动重新 spawn 一次
7. **等待超时**：给 gemini/codex 等设超时，超时后自动 fallback 给 claude

### System Prompt 层

8. **强化频道回复意识**：codex 的 system prompt 需要更强调"完成后必须 @main 回复"
9. **输出格式约束**：让 agent 把长内容写文件 + 频道里只发摘要（当前 claude 做得好，codex 不稳定）

---

## 五、值得固化的模式

### 1. 主协调 + dev + reviewer 三角

最成功的协作模式。固化到 system prompt：
- **dev**："你是开发者，只写代码。遇到不确定的设计决策先回复 main 确认。每完成一步简要回复 main。"
- **reviewer**："你是 code reviewer。按指定格式输出：总体评价 / 必须修复 / 建议改进 / 结论（通过/需要修复后再看）。"
- **main**（人或 agent）：做决策、转发意见、协调流程

### 2. 并行调研 → 汇总决策

给 3+ agent 分配不同方向的调研任务，main 汇总所有结果后做综合判断。
- 关键：每个 agent 的任务要独立，不互相依赖
- 关键：main 等所有结果回来再决策，不被先回来的结果带偏

### 3. 先调研再实现

bus-20260315-143109 的 dev 被要求"先看代码，回复 4 个确认点"，确认后才开始写代码。效果比直接让 agent 动手好得多——减少了返工。

### 4. Review 发现的问题立刻转发给 dev

main 不尝试解释 reviewer 的意见，直接转发 + 拍板哪些要修。减少信息衰减。

### 5. 长内容写文件，频道只发摘要

architect 在 ai-work-os 频道的做法：详细分析写到 notes/ 下的 md 文件，频道里只说"完成，详见 xxx.md"。保持频道信噪比。

---

## 六、数据统计

| 指标 | 值 |
|-----|-----|
| 总频道数 | 12 |
| 有实质协作的频道 | 7（其余为测试/短命） |
| agent 总上线次数 | ~35 |
| agent 出错次数 | 8（gemini 3, c1 2, codex 2, 其他 1） |
| 最长频道 | bus-20260315-194626 (1661 行, ~4.5 小时) |
| 最高效频道 | bus-20260315-143109 (ESOP dev+reviewer, 01+02 完成) |
| agent 间直接通信 | 2 次（alice→bob 链式，codex1→claude1 评审参考） |

---

_Generated by claude1 @ 2026-03-16_
