local lspconfig = require("lspconfig")
local servers = { "pyright", "ruff_lsp", "clangd", "lua_ls", "html", "tsserver"}
local lsputil = require("lspconfig/util")

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
        },
        on_new_config = function(new_config, new_root_dir)
            local py = require("utils.python.lua")
            py.env(new_root_dir)
            new_config.settings.pylsp.plugins.jedi.environment = py.get_python_dir(new_root_dir)
        end,

    }
    lspconfig[server].setup(opts)
end
