local lspconfig = require("lspconfig")
--local servers = { "pyright", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" }
local servers = { "pylsp", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" }

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
