local mason_ok, mason = pcall(require, "mason")
local mason_lsp_ok, mason_lsp = pcall(require, "mason-lspconfig")

if not mason_ok or not mason_lsp_ok then
    return
end

mason_lsp.setup({
    ensure_installed = {
        "lua_ls",
        "clangd",
        "pyright", "ruff_lsp",
        "html", "tsserver"
    },
    automatic_installation = true,
})

local function get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
    }

    local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if not status_ok then
        return capabilities
    end
    return cmp_nvim_lsp.default_capabilities(capabilities)
end

local on_attach = function(client, bufnr)
end
local capabilities = get_capabilities()
local handlers = {
    ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        width = 60,
    }),
    ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { width = 60 }),
}
local lspconfig = require("lspconfig")

require("mason-lspconfig").setup_handlers {
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
