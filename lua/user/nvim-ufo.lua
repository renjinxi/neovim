local status_ok, ufo = pcall(require, "ufo")
if not status_ok then
    return
end

--local ftMap = {
--vim = 'indent',
--python = {'indent'},
--git = ''
--}

vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

--ufo.setup({
--provider_selector = function(bufnr, filetype, buftype)
----return {'lsp','treesitter'}
--return {'lsp','indent'}
--end
--})

local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    --local suffix = ('  %d '):format(endLnum - lnum)
    local suffix = " ..."
    --local suffix = (' ::')
    local sufWidth = vim.fn.strdisplaywidth(suffix)
    local targetWidth = width - sufWidth
    local curWidth = 0
    for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
        else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, { suffix, "MoreMsg" })
    return newVirtText
end

-- global handler
-- `handler` is the 2nd parameter of `setFoldVirtTextHandler`,
-- check out `./lua/ufo.lua` and search `setFoldVirtTextHandler` for detail.
require("ufo").setup({
    --fold_virt_text_handler = handler,
    provider_selector = function(bufnr, filetype, buftype)
        --return {'lsp','treesitter'}
        return { "lsp", "indent" }
    end,
})

-- buffer scope handler
-- will override global handler if it is existed
-- local bufnr = vim.api.nvim_get_current_buf()
-- require('ufo').setFoldVirtTextHandler(bufnr, handler)

--local status_ok, which_key = pcall(require, "which-key")

--if not status_ok then
--return
--end

--local keymap = {
--R = { "<cmd>lua require('ufo').openAllFolds<cr>", "Open All Folds" },
--M = { "<cmd>lua require('ufo').closeAllFolds<cr>", "Close All Folds" },
--}

--local opts = {
--mode = "n",
--prefix = "z",
--buffer = nil,
--silent = true,
--noremap = true,
--nowait = false
--}

--which_key.register(keymap, opts)
vim.cmd("hi Folded guifg=NONE guibg=NONE")
--vim.cmd("highlight FloatBorder guifg=NONE guibg=NONE")
--vim.cmd("hi UfoFoldedEllipsis guibg=NONE")
--vim.cmd("hi UfoFoldedEllipsis guibg=#a892a2")
--#a0baba
--
