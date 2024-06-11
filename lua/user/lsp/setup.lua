-- Setup installer & lsp configs
local mason_ok, mason = pcall(require, "mason")
local mason_lsp_ok, mason_lsp = pcall(require, "mason-lspconfig")

if not mason_ok or not mason_lsp_ok then
    return
end

mason_lsp.setup({
    ensure_installed = {
        "pyright", "ruff_lsp", "clangd", "lua_ls", "html", "tsserver"
    },
    automatic_installation = true,
})

local lspconfig = require("lspconfig")
local on_attach = require("user.lsp.handlers").on_attach
local capabilities = require("user.lsp.handlers").capabilities
local handlers = {
    ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        width = 60,
    }),
    ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { width = 60 }),
}

require("mason-lspconfig").setup_handlers {
    -- The first entry (without a key) will be the default handler
    -- and will be called for each installed server that doesn't have
    -- a dedicated handler.
    function(server_name)
        require("lspconfig")[server_name].setup {
            on_attach = on_attach,
            capabilities = capabilities,
            handlers = handlers,
            on_new_config = function(new_config, new_root_dir)
                local py = require("utils.python.lua")
                py.env(new_root_dir)
                new_config.settings.pylsp.plugins.jedi.environment = py.get_python_dir(new_root_dir)
            end,

        }
    end,


    ["lua_ls"] = function()
        lspconfig.lua_ls.setup({
            capabilities = capabilities,
            handlers = handlers,
            on_attach = on_attach,
            settings = require("user.lsp.servers.lua_ls").settings,
        })
    end
}
