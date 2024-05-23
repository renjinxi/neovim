--vim.cmd("colorscheme dayfox")
--vim.cmd("colorscheme shines")
--
vim.o.background = "light" -- or "dark" for light mode
vim.g.PaperColor_Theme_Options = {
    theme = {
        default = {
            transparent_background = 1
        }
    }
}
vim.cmd("colorscheme PaperColor")
vim.api.nvim_set_hl(0, 'VertSplit', { bg = 'NONE', fg = '#005f87' })

--if vim.g.neovide then
    --vim.cmd("colorscheme PaperColor")
    --vim.api.nvim_set_hl(0, 'VertSplit', { bg = 'NONE', fg = '#005f87' })
--else
    --vim.cmd("colorscheme shines")
--end

--vim.cmd("colorscheme iceberg")
