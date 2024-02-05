local status_ok, lsp_installer = pcall(require, "nvim-lsp-installer")

if not status_ok then
    return
end

local lspconfig = require("lspconfig")
local servers = { "pyright", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo" }

lsp_installer.setup({
    ensure_installed = servers,
})

local root_files = {
    --"pyproject.toml",
    --"setup.py",
    --"setup.cfg",
    --"requirements.txt",
    --"Pipfile",
    --"manage.py",
    "pyrightconfig.json",
    ".git",
    ".gitignore",
}

for _, server in pairs(servers) do
    local opts = {
        --root_dir = require("lspconfig.util").root_pattern(unpack(root_files)),

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

        --python = {
        --analysis = {
        --autoSearchPaths = true,
        --diagnosticMode = "workspace",
        --useLibraryCodeForTypes = false,
        --typeCheckingMode = "off",
        --},
        --},
        --}
    }
    lspconfig[server].setup(opts)
end
