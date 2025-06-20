local M = {}

-- 基础按键设置
local function setup_basic_keymaps()
	local opts = { noremap = true, silent = true }
	local term_opts = { silent = true }

	-- 设置 leader 键 (使用现代化API)
	vim.keymap.set("n", "<space>", "", opts)
	vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", term_opts)

	-- URL 打开功能
	local open_command = vim.fn.has("mac") == 1 and "open" or "xdg-open"

	local function url_repo()
		local cursorword = vim.fn.expand("<cfile>")
		if string.find(cursorword, "^[a-zA-Z0-9-_.]*/[a-zA-Z0-9-_.]*$") then
			cursorword = "https://github.com/" .. cursorword
		end
		return cursorword or ""
	end

	local function open_url()
		vim.fn.jobstart({ open_command, url_repo() }, { detach = true })
	end

	vim.keymap.set("n", "gx", open_url, opts)
end

-- 加载所有子模块
local modules = {
	"editor", -- 编辑器基础功能
	"tools", -- 工具类功能
	"git", -- Git 相关
	"debug", -- 调试相关
	"lsp", -- LSP 相关
	"project", -- 项目管理
}

function M.setup()
	-- 设置基础按键映射
	setup_basic_keymaps()

	-- 按顺序加载所有模块
	for _, module in ipairs(modules) do
		require("plugins.keymaps." .. module).setup()
	end
end

return M
