vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)

require("ufo").setup({
    provider_selector = function(bufnr, filetype, buftype)
        return { "lsp", "indent" }
    end,
})
