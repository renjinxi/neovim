local post_open_hook = function(_, win)
    vim.api.nvim_win_set_option(win, "winhighlight", "Normal:")
end

require("goto-preview").setup({
    post_open_hook = post_open_hook,
})

