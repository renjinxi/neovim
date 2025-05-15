local M = {}

function M.setup()
	-- UI 相关配置
	local ui_options = {
		number = true, -- 显示行号
		cmdheight = 1, -- 命令行高度
		hlsearch = false, -- 禁用搜索高亮保持
		cursorline = true, -- 高亮当前行
		mouse = "", -- 启用所有模式下的鼠标支持
		showtabline = 2, -- 总是显示标签栏
		signcolumn = "auto", -- 自动显示标记列
		laststatus = 3, -- 全局状态栏
		termguicolors = true, -- 启用真彩色支持
		background = "light", -- 设置背景主题
	}

	-- 编辑器行为配置
	local editor_options = {
		expandtab = true, -- 将制表符转换为空格
		autoindent = true, -- 自动缩进
		smartindent = true, -- 智能缩进
		tabstop = 4, -- 制表符等于4个空格
		softtabstop = 4, -- 软制表符
		shiftwidth = 4, -- 缩进宽度
		textwidth = 79, -- 文本宽度
		fileformat = "unix", -- 使用 UNIX 文件格式
		fileencoding = "utf-8", -- 文件编码
		splitright = true, -- 垂直分割时新窗口在右边
		splitbelow = true, -- 水平分割时新窗口在下边
		swapfile = false, -- 禁用交换文件
		clipboard = "unnamedplus", -- 使用系统剪贴板
		scrolloff = 8, -- 光标距离顶部/底部保持的行数
		sidescrolloff = 8, -- 光标距离左/右保持的列数
		wrap = false, -- 不自动换行
		writebackup = false, -- 不创建备份文件
		undofile = true, -- 启用持久撤销
		updatetime = 300, -- 更新时间
		timeoutlen = 500, -- 键盘序列超时时间
		completeopt = "menuone,noselect", -- 补全设置
	}

	-- 代码折叠配置
	local fold_options = {
		foldcolumn = "0", -- 折叠列宽度
		foldlevel = 99, -- 折叠级别
		foldlevelstart = -1, -- 启动时折叠级别
		foldenable = true, -- 启用折叠
	}

	-- 搜索配置
	local search_options = {
		ignorecase = true, -- 搜索忽略大小写
		smartcase = true, -- 智能大小写
	}

	-- 填充字符配置
	local fillchars_options = {
		fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldclose:",
	}

	-- 高亮和差异显示配置
	local highlight_options = {
		-- 差异显示高亮
		-- ["hi DiffText"] = "guifg=#000000 guibg=#ffa07a blend=20",
		["hi DiffAdd"] = "guifg=NONE guibg=#c8e6c9",
		["hi DiffChange"] = "guifg=NONE guibg=#fff9c4",
		["hi DiffDelete"] = "guifg=#ffcdd2 guibg=#ffcdd2",
		["hi DiffText"] = "guifg=NONE guibg=#ffcc80",
	}

	-- 应用所有配置组
	local function apply_options(options)
		for k, v in pairs(options) do
			vim.opt[k] = v
		end
	end

	-- 应用高亮配置
	local function apply_highlights(highlights)
		for cmd, args in pairs(highlights) do
			vim.cmd(cmd .. " " .. args)
		end
	end

	apply_options(ui_options)
	apply_options(editor_options)
	apply_options(fold_options)
	apply_options(search_options)
	apply_options(fillchars_options)
	apply_highlights(highlight_options)

	-- 加载环境变量（仅用于 Python 配置）
	local env = require("core.env")
	local g = vim.g

	-- 设置 Python 路径
	g.python3_host_prog = env.get("NVIM_PYTHON3_HOST_PROG", "/usr/local/bin/python3")

	-- 设置预览配置（使用固定值）
	g.vista_fzf_preview = { "right:50%" }
	g.fzf_preview_window = { "right:50%", "ctrl-/" }

	-- 设置 Leader 键
	g.mapleader = " "
	g.maplocalleader = " "

	-- 定义全局终端按键映射函数
	_G.set_terminal_keymaps = function()
		vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { buffer = true })
		vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { buffer = true })
		vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { buffer = true })
		vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { buffer = true })
		vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = true, noremap = true })
	end

	-- 创建自动命令组用于终端设置
	local term_group = vim.api.nvim_create_augroup("TerminalSettings", { clear = true })

	-- 创建自动命令，对所有终端应用按键映射和设置行号
	vim.api.nvim_create_autocmd("TermOpen", {
		group = term_group,
		pattern = "term://*",
		callback = function()
			-- 应用按键映射
			_G.set_terminal_keymaps()

			-- 设置终端显示行号和相对行号
			vim.opt_local.number = true
			vim.opt_local.relativenumber = true
		end,
	})
end

return M
