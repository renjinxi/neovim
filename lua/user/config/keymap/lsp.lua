local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local keymap = {
	l = {
		name = "LSP", -- naming the prefix group
		-- Note: You have 'lD' defined twice, for 'declaration' and 'type_definition'.
		-- This example keeps the 'type_definition' mapping.
		--c = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
		--e = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic Float" },
		--f = { "<cmd>lua vim.lsp.buf.format { async = true }<CR>", "Format" },
		--r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
		D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Declaration" },
		I = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation" },
		R = { "<cmd>lua vim.lsp.buf.references()<CR>", "References" },

		a = { "<cmd>Lspsaga finder<CR>", "Finder Ref Def" },
		c = { "<cmd>Lspsaga code_action<CR>", "Code Action" },
		d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Definition" },
		e = { "<cmd>Lspsaga show_line_diagnostics <CR>", "Diagnostic Float" },
		f = { "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<CR>", "Format" },
		g = { "<cmd>Lspsaga outgoing_calls<CR>", "Outgoing Calls" },
		i = { "<cmd>Lspsaga incoming_calls<CR>", "Incoming Calls" },
		q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", "Diagnostic Loclist" },
		r = { "<cmd>Lspsaga rename<CR>", "Rename" },
		s = { "<cmd>lua vim.lsp.buf.document_symbol()<CR>", "Document Symbols" },
		sh = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
		wa = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add Workspace Folder" },
		wl = { "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", "List Workspace Folders" },
		wr = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Remove Workspace Folder" },
	},
	["[d"] = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", "Previous Diagnostic" },
	["]d"] = { "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", "Next Diagnostic" },
	--K = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover" }
	K = { "<cmd>Lspsaga hover_doc<CR>", "Hover" },
}

require("which-key").register(keymap, normal_opts)
