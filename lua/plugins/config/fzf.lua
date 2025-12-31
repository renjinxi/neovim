local fzf_lua = require("fzf-lua")

-- fzf-lua setup
fzf_lua.setup({
	files = {
		actions = {
			-- ctrl-g 切换搜索包含 gitignore 文件
			["ctrl-g"] = function()
				fzf_lua.files({ cmd = "fd --hidden --no-ignore" })
			end,
		},
	},
	grep = {
		actions = {
			-- ctrl-g 切换搜索包含 gitignore 文件
			["ctrl-g"] = function()
				fzf_lua.live_grep({ rg_opts = "--no-ignore --hidden --column --line-number --no-heading --color=always --smart-case" })
			end,
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
	fzf_lua.fzf_exec("fd --type d", opts)
end

-- 注册Neovim命令
vim.api.nvim_create_user_command("Fcd", ChangeDirectory, {})
