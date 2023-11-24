local status_ok, nvim_lsp = pcall(require, "lspconfig")
if not status_ok then
	return
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	-- Enable completion triggered by <c-x><c-o>
	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings.
	local opts = { noremap = true, silent = true }

	-- See `:help vim.lsp.*` for documentation on any of the below functions
	buf_set_keymap("n", "<leader>ls", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
	buf_set_keymap("n", "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "<leader>lI", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	buf_set_keymap("n", "<leader>lsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "<leader>lwa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<leader>lwr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<leader>lwl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
	buf_set_keymap("n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	buf_set_keymap("n", "<leader>lc", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	buf_set_keymap("n", "<leader>lR", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
        buf_set_keymap("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format { async = true }<CR>", opts)
	buf_set_keymap("n", "<leader>lD", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
	buf_set_keymap("n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<leader>lq", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)

	--if not status_ok then
	--return
	--end

	--local keymap = {
	--l = {
	--name = "LSP",
	--s = {"<cmd>lua vim.lsp.buf.document_symbol()<CR>", "Document Symbol" },
	--D = {"<cmd>lua vim.lsp.buf.declaration()<CR>", "Declaration"},
	--d = {"<cmd>lua vim.lsp.buf.definition()<CR>", "")},
	--I = {"<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation"},
	--sh = {"<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help"},
	--wa = {"<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add WorkSpace"},
	--wr = {"<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Delete WorkerSpace"},
	--wl = {"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", "List WorkSpace"},
	--r = {"<cmd>lua vim.lsp.buf.rename()<CR>", "Rename"},
	--c = {"<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action"},
	--R = {"<cmd>lua vim.lsp.buf.references()<CR>", "References"},
	--f = {"<cmd>lua vim.lsp.buf.formatting()<CR>", "Formatting"},
	--D = {"<cmd>lua vim.lsp.buf.type_definition()<CR>", "Type Definition"},
	--e = {"<cmd>lua vim.diagnostic.open_float()<CR>", "Open Diagnostic Float"},
	--K = {"<cmd>lua vim.lsp.buf.hover()<CR>", "Hover"},
	--p = {"<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", "Diagnostic Pre"},
	--n = {"<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", "Diagnostic Next"},
	--q = {"<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", "Diagnostic Set Loclist"},
	--}
	--}

	--local opts = {
	--mode = "n",
	--prefix = "<leader>",
	--buffer = bufnr,
	--silent = true,
	--noremap = true,
	--nowait = false
	--}

	--which_key.register(keymap, opts)
end

--Use a loop to conveniently call 'setup' on multiple servers and
--map buffer local keybindings when the language server attaches
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
local servers = { "pyright", "ruff_lsp", "clangd", "lua_ls" }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
		--flags = {
		--debounce_text_changes = 150,
		--}
	})
end
