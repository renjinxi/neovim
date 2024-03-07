local status_ok, lsp_installer = pcall(require, "nvim-lsp-installer")

if not status_ok then
    return
end

local lspconfig = require("lspconfig")
local servers = { "pyright", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" }

lsp_installer.setup({
    ensure_installed = servers,
})

for _, server in pairs(servers) do
    local opts = {
        on_attach = require("user.lsp.handlers").on_attach,
        capabilities = require("user.lsp.handlers").capabilities,
        settings = {
            Lua = {
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = { 'vim' },
                },
            },
        }

    }
    lspconfig[server].setup(opts)
end
