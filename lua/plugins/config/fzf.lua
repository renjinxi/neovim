local fzf_lua = require("fzf-lua")
local actions = require("fzf-lua.actions")

-- fzf-lua setup
fzf_lua.setup({
	files = {
		fd_opts = "--color=never --type f --hidden --follow --exclude .git",
		actions = {
			-- ctrl-g 切换 gitignore (用内置 action，支持状态显示)
			["ctrl-g"] = { fn = actions.toggle_ignore, reuse = true, header = false },
		},
	},
	grep = {
		rg_opts = "--column --line-number --no-heading --color=always --smart-case --follow --max-columns=4096 -e",
		actions = {
			["ctrl-g"] = { fn = actions.toggle_ignore, reuse = true, header = false },
		},
	},
})

function ChangeDirectory(opts)
	opts = opts or {}
	opts.prompt = "Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x)
	end
	opts.actions = {
		["default"] = function(selected)
			vim.cmd("cd " .. selected[1])
		end,
	}
	fzf_lua.fzf_exec("fd --type d --follow", opts)
end

-- 注册Neovim命令
vim.api.nvim_create_user_command("Fcd", ChangeDirectory, {})
