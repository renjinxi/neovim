local lspconfig = require("lspconfig")
--local servers = { "pyright", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" }
local servers = { "pyright", "pylsp", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" }
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
            pylsp = {
                cmd_env = {
                    VIRTUAL_ENV = ".venv",
                    PATH = lsputil.path.join(".venv", "bin") .. ":" .. vim.env.PATH,
                },
                plugins = {
                    jedi = { environment = ".venv/bin/python" },
                    flake8 = { enabled = false },
                    pycodestyle = { enabled  = false },
                    rope_autoimport = {
                        enabled = true,
                    }
                }
                --pylsp.plugins.rope_autoimport.enabled
            }
        },
        on_new_config = function(new_config, new_root_dir)
            local py = require("utils.python.lua")
            py.env(new_root_dir)
            new_config.settings.pylsp.plugins.jedi.environment = py.get_python_dir(new_root_dir)
        end,

    }
    lspconfig[server].setup(opts)
end
