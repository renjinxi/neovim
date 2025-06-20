local M = {}

function M.setup()
	local keymap = {
		{ "<leader>K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover", nowait = false, remap = false },
		{
			"<leader>[d",
			"<cmd>lua vim.diagnostic.goto_prev()<CR>",
			desc = "Previous Diagnostic",
			nowait = false,
			remap = false,
		},
		{
			"<leader>]d",
			"<cmd>lua vim.diagnostic.goto_next()<CR>",
			desc = "Next Diagnostic",
			nowait = false,
			remap = false,
		},
		{ "<leader>l", group = "LSP", nowait = false, remap = false },
		{ "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "Declaration", nowait = false, remap = false },
		{
			"<leader>lI",
			"<cmd>lua vim.lsp.buf.implementation()<CR>",
			desc = "Implementation",
			nowait = false,
			remap = false,
		},
		{ "<leader>lR", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "References", nowait = false, remap = false },
		{ "<leader>la", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "Find References", nowait = false, remap = false },
		{ "<leader>lc", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Action", nowait = false, remap = false },
		{ "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Definition", nowait = false, remap = false },
		{
			"<leader>le",
			"<cmd>lua vim.diagnostic.open_float()<CR>",
			desc = "Diagnostic Float",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lf",
			"<cmd>lua vim.lsp.buf.format({ async = true })<CR>",
			desc = "Format",
			nowait = false,
			remap = false,
		},
		{ "<leader>lg", "<cmd>Telescope lsp_outgoing_calls<CR>", desc = "Outgoing Calls", nowait = false, remap = false },
		{ "<leader>li", "<cmd>Telescope lsp_incoming_calls<CR>", desc = "Incoming Calls", nowait = false, remap = false },
		{
			"<leader>lq",
			"<cmd>lua vim.diagnostic.setloclist()<CR>",
			desc = "Diagnostic Loclist",
			nowait = false,
			remap = false,
		},
		{ "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename", nowait = false, remap = false },
		{
			"<leader>ls",
			"<cmd>lua vim.lsp.buf.document_symbol()<CR>",
			desc = "Document Symbols",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lsh",
			"<cmd>lua vim.lsp.buf.signature_help()<CR>",
			desc = "Signature Help",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lwa",
			"<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
			desc = "Add Workspace Folder",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lwl",
			"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
			desc = "List Workspace Folders",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lwr",
			"<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
			desc = "Remove Workspace Folder",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
