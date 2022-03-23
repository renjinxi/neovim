local status_ok, neogen = pcall(require, "neogen")
if not status_ok then
	return
end

neogen.setup({
	enabled = true,
	languages = {
		python = {
			template = {
				annotation_convention = "google_docstrings", -- for a full list of annotation_conventions, see supported-languages below,
			},
		},
	},
})

local status_ok, which_key = pcall(require, "which-key")

if not status_ok then
	return
end

local M = {}

function M.setup()
	local keymap = {
		n = {
			name = "Annotation",
			f = { "<cmd>lua require('neogen').generate({ type = 'func' })<CR>", "Func" },
			c = { "<cmd>lua require('neogen').generate({ type = 'class' })<CR>", "Class" },
			t = { "<cmd>lua require('neogen').generate({ type = 'type' })<CR>", "Type" },
			e = { "<cmd>lua require('neogen').generate({ type = 'file' })<CR>", "File" },
		},
	}

	which_key.register(keymap, {
		mode = "n",
		prefix = "<leader>",
		buffer = nil,
		silent = true,
		noremap = true,
		nowait = false,
	})
end

M.setup()
