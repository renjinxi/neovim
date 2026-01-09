-- ============================================================================
-- Keymaps 入口文件
-- 所有快捷键统一在 all.lua 中定义
-- ============================================================================
local M = {}

-- 基础按键设置 (leader 键等)
local function setup_basic_keymaps()
	local opts = { noremap = true, silent = true }

	-- 设置 leader 键
	vim.keymap.set("n", "<space>", "", opts)

	-- URL 打开功能
	local open_command = vim.fn.has("mac") == 1 and "open" or "xdg-open"

	local function url_repo()
		local line = vim.fn.getline(".")
		local col = vim.fn.col(".")

		-- 匹配 URL 模式
		local url_pattern = "https?://[%w%-%.%_%~%:%/%?%#%[%]%@%!%$%&%'%(%)%*%+%,%;%=]+"

		-- 找到光标所在的 URL
		for url in string.gmatch(line, url_pattern) do
			local start_pos, end_pos = string.find(line, url, 1, true)
			if start_pos and col >= start_pos and col <= end_pos then
				-- 去掉末尾的标点
				url = url:gsub("[,;%.%)]$", "")
				return url
			end
		end

		-- fallback: github 短链接
		local cursorword = vim.fn.expand("<cWORD>")
		if string.find(cursorword, "^[a-zA-Z0-9-_.]*/[a-zA-Z0-9-_.]*$") then
			return "https://github.com/" .. cursorword
		end

		return vim.fn.expand("<cfile>")
	end

	local function open_url()
		vim.fn.jobstart({ open_command, url_repo() }, { detach = true })
	end

	vim.keymap.set("n", "gx", open_url, opts)
end

function M.setup()
	-- 设置基础按键映射
	setup_basic_keymaps()

	-- VSCode/Cursor 环境：不加载完整 keymap
	if vim.g.vscode then
		return
	end

	-- 原生 Neovim 环境：加载统一的 keymap 配置
	require("plugins.keymaps.all").setup()
end

return M
