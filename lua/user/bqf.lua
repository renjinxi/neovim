vim.cmd([[
        hi default link BqfPreviewFloat Normal
        hi default link BqfPreviewBorder FloatBorder
        hi default link BqfPreviewTitle Title
        hi default link BqfPreviewThumb PmenuThumb
        hi default link BqfPreviewSbar PmenuSbar
        hi default link BqfPreviewCursor Cursor
        hi default link BqfPreviewCursorLine CursorLine
        hi default link BqfPreviewRange IncSearch
        hi default link BqfPreviewBufLabel BqfPreviewRange
        hi default BqfSign ctermfg=14 guifg=Cyan
]])

local status_ok, which_key = pcall(require, "which-key")

if not status_ok then
        return
end

local keymap = {
        c = {
                name = "QuickWindow",
                n = { "<cmd>cnext<cr>", "Next item" },
                p = { "<cmd>cprevious<cr>", "Previous item" },
                o = { "<cmd>copen<cr>", "Open" },
                l = { "<cmd>cclose<cr>", "Close" },
        },
}

local opts = {
        mode = "n",
        prefix = "<leader>",
        buffer = nil,
        silent = true,
        noremap = true,
        nowait = false,
}

which_key.register(keymap, opts)
