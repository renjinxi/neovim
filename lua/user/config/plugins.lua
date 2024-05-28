return {
    -- manage itself
    "folke/lazy.nvim",
    "neovim/nvim-lspconfig",
    "Pocco81/auto-save.nvim",

    {
        "antosha417/nvim-lsp-file-operations",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-tree.lua",
        },
        --config = function()
        --require("lsp-file-operations").setup()
        --end,
    },

    -- quick move
    "folke/trouble.nvim",
    {
        "ggandor/leap.nvim",
        config = function()
            require("leap").add_default_mappings()
        end,
    },
    {
        "ggandor/flit.nvim",
        config = function()
            require('flit').setup {
                keys = { f = 'f', F = 'F', t = 't', T = 'T' },
                -- A string like "nv", "nvo", "o", etc.
                labeled_modes = "v",
                multiline = true,
                -- Like `leap`s similar argument (call-specific overrides).
                -- E.g.: opts = { equivalence_classes = {} }
                opts = {}
            }
        end
    },

    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    'nvim-telescope/telescope-ui-select.nvim',
    --"nvim-lua/plenary.nvim",

    -- tree syntc
    {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate"
    },
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
    --{ "AndreM222/copilot-lualine" },

    -- file explorer
    "nvim-tree/nvim-tree.lua",

    "nvim-tree/nvim-web-devicons",

    -- git
    "tpope/vim-fugitive",
    {
        "wintermute-cell/gitignore.nvim",
        config = function()
            require('gitignore')
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        requires = {
            "nvim-lua/plenary.nvim",
        }
    },

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

    { "akinsho/toggleterm.nvim",             version = "*" },

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
                            --"repl"
                            { id = "repl",    size = 0.7 }, -- Adjusts the height to 25% of the layout area
                            { id = "console", size = 0.3 },
                        },
                        size = 0.3,          -- Adjusts the height to 25% of the Neovim window height
                        position = "bottom", -- Position at the bottom
                    },
                }
            })
        end
    },
    "nvim-neotest/nvim-nio",
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
    {
        'Weissle/persistent-breakpoints.nvim',
        config = function()
            require('persistent-breakpoints').setup {
                load_breakpoints_event = { "BufReadPost" }
            }
        end
    },

    -- folding
    { "kevinhwang91/nvim-ufo", dependencies = "kevinhwang91/promise-async" },

    "danymat/neogen",

    -- theme for neovim
    {
        'NLKNguyen/papercolor-theme',
        --config = function()
        --vim.o.background = "light" -- or "dark" for light mode
        --vim.cmd("colorscheme PaperColor")
        --end
    },

    -- go to small window
    "rmagatti/goto-preview",

    -- quickfix window
    "kevinhwang91/nvim-bqf",

    -- optional
    --"junegunn/fzf",
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
        end,
        opts = {},
    },

    -- diff
    "sindrets/diffview.nvim",
    -- Lua
    --{
    --"Pocco81/true-zen.nvim",
    --config = function()
    --require("true-zen").setup({
    ---- your config goes here
    ---- or just leave it empty :)
    --})
    --end,
    --},

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
        --config = function()
        ----require("chatgpt").setup({})
        --require("chatgpt").setup({
        --chat = {
        --keymaps = {
        --next_message = "<C-l>",
        --},
        --},
        --popup_window = {
        --border = {
        --highlight = "CustomFloatBorder",
        --}
        --},
        --popup_input = {
        --border = {
        --highlight = "CustomFloatBorder",
        --},
        --},
        ----openai_params = {
        ----model = "gpt-3.5-turbo",
        ------model = "gpt-4-turbo-preview",
        ----frequency_penalty = 0,
        ----presence_penalty = 0,
        ----max_tokens = 300,
        ----temperature = 0,
        ----top_p = 1,
        ----n = 1,
        ----},
        --actions_paths = { "~/.config/nvim/lua/user/chatgpt/actions.json" },
        --})
        --end,
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "folke/trouble.nvim",
            "nvim-telescope/telescope.nvim"
        }
    },
    -- startuptime
    "dstein64/vim-startuptime",
    --"github/copilot.lua"
    --{
    --'Exafunction/codeium.vim',
    --event = 'BufEnter'
    --},
    --{
    --"Exafunction/codeium.nvim",
    --dependencies = {
    --"nvim-lua/plenary.nvim",
    --"hrsh7th/nvim-cmp",
    --},
    ----config = function()
    ----require("codeium").setup({
    ----})
    ----end
    --},
    --{
    --"zbirenbaum/copilot.lua",
    --event = "InsertEnter",
    --config = function()
    --require("copilot").setup({
    --suggestion = {
    --enabled = false,
    ----keymap = {
    ----next = "<M-7>",
    ----prev = "<M-4>",
    ----}
    --},
    --panel = {
    --enabled = false,
    --},
    --})
    --end,
    --},
    --{
    --"zbirenbaum/copilot-cmp",
    --config = function()
    --require("copilot_cmp").setup()
    --end
    --},
    --{
    --"CopilotC-Nvim/CopilotChat.nvim",
    --branch = "canary",
    --dependencies = {
    --{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    --{ "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
    --},
    --opts = {
    --debug = true, -- Enable debugging
    ---- See Configuration section for rest
    --},
    ---- See Commands section for default commands if you want to lazy load on them
    --},
    --
    -- unit test
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter"
        },
    },
    "nvim-neotest/neotest-python",
    {
        "andythigpen/nvim-coverage",
        requires = "nvim-lua/plenary.nvim",
        -- Optional: needed for PHP when using the cobertura parser
        rocks = { 'lua-xmlreader' },
        --config = function()
        --require("coverage").setup()
        --end,
    },
    -- todo highlight
    --{
    --"folke/todo-comments.nvim",
    --dependencies = { "nvim-lua/plenary.nvim" },
    --opts = {
    ---- your configuration comes here
    ---- or leave it empty to use the default settings
    ---- refer to the configuration section below
    --}
    --}
    --{
    --'rmagatti/auto-session',
    --config = function()
    --require("auto-session").setup {
    --log_level = "error",
    --auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    --}
    --end
    --},
    {
        'norcalli/nvim-colorizer.lua',
        config = function()
            require('colorizer').setup()
        end
    },
    --project manager
    {
        "ahmedkhalf/project.nvim",
        config = function()
            require("project_nvim").setup {
                scope_chdir = "tab",
            }
        end
    },
    -- gitlab
    {
        "harrisoncramer/gitlab.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "stevearc/dressing.nvim",     -- Recommended but not required. Better UI for pickers.
            "nvim-tree/nvim-web-devicons" -- Recommended but not required. Icons in discussion tree.
        },
        enabled = true,
        build = function() require("gitlab.server").build(true) end, -- Builds the Go binary
        config = function()
            require("gitlab").setup({
                debug = {
                    go_request = true,
                    go_response = true,
                },
            })
        end,
    },

    'nvimdev/lspsaga.nvim',
    --config = function()
    --require('lspsaga').setup()
    ----ss
    ----print("test")
    --end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',     -- optional
    },
    {
        "michaelb/sniprun",
        branch = "master",

        build = "sh install.sh",
        -- do 'sh install.sh 1' if you want to force compile locally
        -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

        config = function()
            require("sniprun").setup({
                -- your options
            })
        end,
    },
    {
        'stevearc/conform.nvim',
        opts = {},
    },
    {
        'pwntester/octo.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            -- OR 'ibhagwan/fzf-lua',
            'nvim-tree/nvim-web-devicons',
        },
        --config = function()
        --require "octo".setup()
        --end
    },
    -- image show
    {
        "edluffy/hologram.nvim",
        --config = function()
            --require('hologram').setup {
                --auto_display = true -- WIP automatic markdown image display, may be prone to breaking
            --}
        --end
    },
    {
        'mikesmithgh/kitty-scrollback.nvim',
        enabled = true,
        lazy = true,
        cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth' },
        event = { 'User KittyScrollbackLaunch' },
        -- version = '*', -- latest stable version, may have breaking changes if major version changed
        -- version = '^4.0.0', -- pin major version, include fixes and features that do not have breaking changes
        config = function()
            require('kitty-scrollback').setup()
        end,
    },
    {
        "willothy/flatten.nvim",
        config = function()
            require("flatten").setup({
                window = {
                    open = "vsplit"
                }
            })
        end,
        -- or pass configuration with
        -- opts = {  }
        -- Ensure that it runs first to minimize delay when opening file from terminal
        lazy = false,
        priority = 1001,
    },
    {
        'chipsenkbeil/distant.nvim',
        branch = 'v0.3',
        config = function()
            require('distant'):setup()
        end
    },
}
