# ACP 快捷键精简方案

## 现状问题

- 6 个命令全在 `<leader>ai*` 下，最少 4 次按键
- `<leader>a` 被 REST 占了，`<leader>ai` 是二级前缀

## 可用空位

分析 all.lua，完全空闲的 `<leader>` 单字母前缀：**h, k, u**

- `h` — 直觉上像 help
- `k` — 不太直觉
- `u` — 可以理解为 "unified" / "union"（频道的意思）

另外 `<leader>n` 只用了 `<leader>nd`（daily note），其余全空。

## 方案：`<leader>u` + `<A-u>` 组合

### 核心思路

1. **最高频操作用 Alt 键**：`<A-u>` toggle（2 次按键，全模式可用）
2. **次高频用 `<leader>u*`**：3 次按键内到达
3. **合并命令**：AcpAgents 是最全的入口，升级为主命令

### 快捷键分配

| 快捷键 | 命令 | 按键数 | 说明 |
|--------|------|--------|------|
| `<A-u>` | AcpToggle | 2 | 最高频：toggle 当前活跃窗口 |
| `<leader>u` | AcpAgents | 2 | 主入口：选择/toggle 任意 session |
| `<leader>uc` | AcpChat | 3 | 开新私聊 |
| `<leader>ub` | AcpBus | 3 | 开/toggle 频道 |
| `<leader>us` | AcpBusSelect | 3 | 恢复已保存频道 |
| `<leader>uq` | AcpStop | 3 | 关闭所有 |

### 与现有布局的兼容

- `<A-u>` 当前未使用（Alt 键区 `<A-1>`~`<A-9>` + `<A-a/g/k/l/n/q/s/t/w>` 已占，u 空闲）
- `<leader>u` 完全空闲
- 旧的 `<leader>ai*` 可以保留一段时间做过渡，之后删除

### 命令简化思考

AcpAgents（picker）其实可以替代 AcpChat 和 AcpBus 的场景——用户选一个 session toggle，或在 picker 里新建。但新建需要额外交互（选 adapter），所以保留 `<leader>uc` / `<leader>ub` 作为快捷入口。

AcpToggle（`<A-u>`）是盲操作：不需要看选项，直接 toggle 最近活跃的窗口。这在编码过程中最常用。

### 代码改动

```lua
-- alt_mappings 加一条
{ "<A-u>", "<cmd>AcpToggle<cr>", desc = "ACP Toggle", mode = { "n", "i", "v", "t" } },

-- mappings 里替换 <leader>ai 组
{ "<leader>u", "<cmd>AcpAgents<cr>", desc = "ACP: 选择 session" },
{ "<leader>uc", "<cmd>AcpChat claude<cr>", desc = "ACP: Claude 私聊" },
{ "<leader>ub", "<cmd>AcpBus<cr>", desc = "ACP: 频道" },
{ "<leader>us", "<cmd>AcpBusSelect<cr>", desc = "ACP: 恢复频道" },
{ "<leader>uq", "<cmd>AcpStop<cr>", desc = "ACP: 关闭所有" },

-- 删除旧的 <leader>ai* 组（或暂时保留做过渡）
```

### 助记

- **u** = unified（统一协作入口）
- **Alt+u** = 最快 toggle
- uc = u + chat
- ub = u + bus
- us = u + select
- uq = u + quit
