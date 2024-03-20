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

vim.g.mapleader = " "
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

local plugins = {
    -- manage itself
    "folke/lazy.nvim",
    "neovim/nvim-lspconfig",
    "Pocco81/auto-save.nvim",

    -- quick move
    "folke/trouble.nvim",
    {
        "ggandor/leap.nvim",
        config = function()
            require("leap").add_default_mappings()
        end,
    },

    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    --"nvim-lua/plenary.nvim",

    -- tree syntc
    "nvim-treesitter/nvim-treesitter",
    "nvim-treesitter/nvim-treesitter-context",

    -- cmp
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "onsails/lspkind.nvim",

    -- 代码段提示
    {

        "L3MON4D3/LuaSnip",
        dependencies = {
            "saadparwaiz1/cmp_luasnip",     -- Snippets source for nvim-cmp
            "rafamadriz/friendly-snippets", --代码段合集
        },
    },

    -- status line
    "nvim-lualine/lualine.nvim",
    { "AndreM222/copilot-lualine" },

    -- file explorer
    "nvim-tree/nvim-tree.lua",

    "nvim-tree/nvim-web-devicons",

    -- git
    "tpope/vim-fugitive",

    -- indent line
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

    -- auto pairs
    {
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup()
        end,
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end,
    },

    -- quick comment
    "preservim/nerdcommenter",

    -- which key
    "folke/which-key.nvim",

    { "akinsho/toggleterm.nvim", version = "*" },

    {

        "iamcco/markdown-preview.nvim",
        config = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
    {
        "simrat39/symbols-outline.nvim",
        config = function()
            require("symbols-outline").setup()
        end
    },

    --debug for python
    "mfussenegger/nvim-dap",
    "Pocco81/dap-buddy.nvim",
    {
        "rcarriga/nvim-dap-ui",
        config = function()
            require("dapui").setup({
                layouts = {
                    {
                        elements = {
                            -- Elements to include in this layout
                            { id = "scopes",      size = 0.25 }, -- Adjusts the height to 25% of the layout area
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks",      size = 0.25 },
                            { id = "watches",     size = 0.25 },
                        },
                        size = 0.3,        -- Adjusts the width to 40 columns
                        position = "left", -- Position the layout to the left of the Neovim window
                    },
                    {
                        elements = {
                            "repl"
                            --{ id = "repl",    size = 0.3 },   -- Adjusts the height to 25% of the layout area
                            --{ id = "console", size = 0.3 },
                        },
                        size = 0.3,          -- Adjusts the height to 25% of the Neovim window height
                        position = "bottom", -- Position at the bottom
                    },
                }
            })
        end
    },
    {
        "folke/neodev.nvim",
        opts = {},
        config = function()
            --require("neodev").setup({
            --library = { plugins = { "nvim-dap-ui" }, types = true },
            --})
        end
    },
    "mfussenegger/nvim-dap-python",
    "nvim-telescope/telescope-dap.nvim",
    "theHamsta/nvim-dap-virtual-text",

    -- folding
    { "kevinhwang91/nvim-ufo",   dependencies = "kevinhwang91/promise-async" },

    "danymat/neogen",

    -- theme for neovim

    -- go to small window
    "rmagatti/goto-preview",

    -- quickfix window
    "kevinhwang91/nvim-bqf",

    -- optional
    "junegunn/fzf",
    {
        "ibhagwan/fzf-lua",
        -- optional for icon support
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- calling `setup` is optional for customization
            require("fzf-lua").setup({})
        end,
    },
    -- lazy.nvim

    -- habit
    {
        "m4xshen/hardtime.nvim",
        dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
        config = function()
            require("hardtime").setup()
        end,
        opts = {},
    },

    -- diff
    "sindrets/diffview.nvim",
    -- Lua
    {
        "Pocco81/true-zen.nvim",
        config = function()
            require("true-zen").setup({
                -- your config goes here
                -- or just leave it empty :)
            })
        end,
    },

    -- start screen
    {
        "goolord/alpha-nvim",
        config = function()
            --require'alpha'.setup(require'alpha.themes.dashboard'.config)
            require("alpha").setup(require("alpha.themes.startify").config)
        end,
    },

    -- file browser

    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    },

    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    --{
    --'williamboman/mason-lspconfig',
    --config = function()
    --require("mason-lspconfig").setup({
    ---- Automatically install LSP servers
    --ensure_installed = { "pyright", "biome", "ruff_lsp", "clangd", "lua_ls", "taplo", "yamlls" },
    ---- Automatically configure installed servers with nvim-lspconfig
    --automatic_installation = true,
    --})
    --end

    --},

    --chatgpt
    {
        "jackMort/ChatGPT.nvim",
        event = "VeryLazy",
        config = function()
            --require("chatgpt").setup({})
            require("chatgpt").setup({
                --openai_params = {
                --model = "gpt-3.5-turbo",
                ----model = "gpt-4-turbo-preview",
                --frequency_penalty = 0,
                --presence_penalty = 0,
                --max_tokens = 300,
                --temperature = 0,
                --top_p = 1,
                --n = 1,
                --},
                actions_paths = { "~/.config/nvim/lua/user/chatgpt/actions.json" },
            })
        end,
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "folke/trouble.nvim",
            "nvim-telescope/telescope.nvim"
        }
    },
    --{
    --'Exafunction/codeium.vim',
    --event = 'BufEnter'
    --},
    -- startuptime
    "dstein64/vim-startuptime",
    --"github/copilot.lua"
    {
        "zbirenbaum/copilot.lua",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({})
        end,
    },
    {
        "zbirenbaum/copilot-cmp",
        config = function()
            require("copilot_cmp").setup()
        end
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
        },
        opts = {
            debug = true, -- Enable debugging
            -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
    },


}
return lazy.setup(plugins, opt)
