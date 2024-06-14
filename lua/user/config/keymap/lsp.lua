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
        s = { "<cmd>lua vim.lsp.buf.document_symbol()<CR>", "Document Symbols" },
        D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Declaration" },
        d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Definition" },
        I = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation" },
        sh = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
        wa = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add Workspace Folder" },
        wr = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Remove Workspace Folder" },
        wl = { "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", "List Workspace Folders" },
        --r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
        r = { "<cmd>Lspsaga rename<CR>", "Rename" },
        --c = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
        c = { "<cmd>Lspsaga code_action<CR>", "Code Action" },
        g = { "<cmd>Lspsaga outgoing_calls<CR>", "Outgoing Calls" },
        i = { "<cmd>Lspsaga incoming_calls<CR>", "Incoming Calls" },
        a = { "<cmd>Lspsaga finder<CR>", "Finder Ref Def" },
        R = { "<cmd>lua vim.lsp.buf.references()<CR>", "References" },
        --f = { "<cmd>lua vim.lsp.buf.format { async = true }<CR>", "Format" },
        f = { "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<CR>", "Format" },
        -- Note: You have 'lD' defined twice, for 'declaration' and 'type_definition'.
        -- This example keeps the 'type_definition' mapping.
        --e = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic Float" },
        e = { "<cmd>Lspsaga show_line_diagnostics <CR>", "Diagnostic Float" },
        q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", "Diagnostic Loclist" },
    },
    ["[d"] = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", "Previous Diagnostic" },
    ["]d"] = { "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", "Next Diagnostic" },
    --K = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover" }
    K = { "<cmd>Lspsaga hover_doc<CR>", "Hover" }
}

require("which-key").register(keymap, normal_opts)
