vim.cmd("highlight  CustomFloatBorder ctermfg=16 ctermbg=231 guifg=#000000 guibg=#ffffff")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local status_ok, lazy = pcall(require, "lazy")

if not status_ok then
    return
end

local opt = {
    install = {
        missing = true,
        --colorscheme = { "PaperColor" },
    },
}

return lazy.setup("user.config.plugins", opt)
