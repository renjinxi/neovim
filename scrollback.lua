-- ================================
-- Kitty Scrollback 专用最小配置
-- 目标: 快速启动 + Flash.nvim 跳转复制
-- ================================

-- 基本设置
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"  -- 系统剪贴板
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Leader 键
vim.g.mapleader = " "

-- 禁用不需要的内置插件，加速启动
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

-- ================================
-- 插件管理 (lazy.nvim)
-- ================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 插件列表：只加载必要的插件
require("lazy").setup({
  -- 主题 (快速加载)
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "dawn",  -- dawn, moon, or main
        dark_variant = "main",
        disable_background = false,
        disable_italics = true,
      })
      vim.cmd("colorscheme rose-pine")
    end,
  },

  -- Flash.nvim - 快速跳转 (核心功能)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      search = {
        forward = true,
        multi_window = false,  -- scrollback 通常在单窗口
        wrap = true,
      },
      jump = {
        jumplist = true,
        pos = "start",
      },
      label = {
        uppercase = true,
        rainbow = { enabled = false },
      },
      modes = {
        char = {
          enabled = true,
          keys = { "f", "F", "t", "T", ";", "," },
        },
        search = {
          enabled = true,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash Jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
    },
  },

  -- Treesitter (可选，提供更好的语法高亮)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "bash", "python", "lua", "vim", "json", "yaml" },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = { enable = false },
        indent = { enable = false },
      })
    end,
  },
}, {
  -- Lazy.nvim 配置
  performance = {
    cache = {
      enabled = true,
    },
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- ================================
-- 快捷键映射
-- ================================

-- 快速退出
vim.keymap.set("n", "q", "<cmd>qa!<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search" })

-- 复制相关
vim.keymap.set("v", "y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "yy", '"+yy', { desc = "Yank line to clipboard" })
vim.keymap.set("v", "Y", '"+Y', { desc = "Yank to clipboard" })

-- 搜索增强
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- 滚动
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- 快速移动到文件首尾
vim.keymap.set("n", "gg", "gg0", { desc = "Go to top" })
vim.keymap.set("n", "G", "G$", { desc = "Go to bottom" })

-- ================================
-- 自动命令
-- ================================

-- 进入时自动到底部 (scrollback 通常查看最新内容)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("normal! G")
  end,
})

-- 高亮 yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Flash 高亮优化 (适配 light 主题)
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local bg = vim.o.background
    if bg == "light" then
      vim.api.nvim_set_hl(0, "FlashLabel", {
        fg = "#ffffff",
        bg = "#2563eb",
        bold = true,
      })
      vim.api.nvim_set_hl(0, "FlashMatch", {
        fg = "#1f2937",
        bg = "#fef3c7",
        bold = true,
      })
    end
  end,
})

-- ================================
-- 状态栏 (简化版)
-- ================================
vim.opt.statusline = " SCROLLBACK | Press 's' to jump, 'q' to quit, 'y' to yank "
