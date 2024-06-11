-- TODO: backfill this to templateilluminate
local function lsp_highlight_document(client)
    -- Set autocommands conditional on server_capabilities
    local status_ok, illuminate = pcall(require, "illuminate")
    if not status_ok then
        return
    end
    illuminate.on_attach(client)
    -- end
end

local on_attach = function(client, bufnr)
    lsp_highlight_document(client)
end

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

local capabilities = get_capabilities()

return {
    on_attach = on_attach,
    capabilities = capabilities
}
