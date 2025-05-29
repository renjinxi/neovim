local signs = {
	{ name = "DiagnosticSignError", text = "✘", texthl = "DiagnosticSignError" },
	{ name = "DiagnosticSignWarn", text = "▲", texthl = "DiagnosticSignWarn" },
	{ name = "DiagnosticSignHint", text = "⚡", texthl = "DiagnosticSignHint" },
	{ name = "DiagnosticSignInfo", text = "»", texthl = "DiagnosticSignInfo" },
}

-- 定义诊断符号
for _, sign in ipairs(signs) do
	vim.fn.sign_define(sign.name, {
		text = sign.text,
		texthl = sign.name,
		numhl = "",
	})
end

local config = {
	-- disable virtual text
	virtual_text = false,
	-- virtual_text = {
	--     -- source = "always",  -- Or "if_many"
	--     prefix = "●", -- Could be '■', '▎', 'x'
	-- },
	-- show signs
	signs = true,
	-- signs = {
	-- 	active = signs,
	-- },
	update_in_insert = true,
	underline = true,
	severity_sort = true,
	float = {
		focusable = false,
		style = "minimal",
		--border = "",
		source = "always",
		header = "",
		prefix = "",
	},
}

vim.diagnostic.config(config)
