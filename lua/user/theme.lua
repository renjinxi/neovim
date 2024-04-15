--vim.cmd("colorscheme dayfox")
--vim.cmd("colorscheme shines")
--
vim.g.PaperColor_Theme_Options = {
    theme = {
        default = {
            transparent_background = 1
        }
    }
}
vim.o.background = "light" -- or "dark" for light mode
--vim.o.background = "dark" -- or "dark" for light mode
vim.cmd("colorscheme PaperColor")
vim.api.nvim_set_hl(0, 'VertSplit', { bg = 'NONE', fg = '#005f87' })

--vim.cmd("colorscheme iceberg")
