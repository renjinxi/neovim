return {
	-- manage itself
	"folke/lazy.nvim",
	-- ================================
	-- LSP 和代码服务器管理 (2025年现代化配置)
	-- ================================
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗"
					}
				},
				max_concurrent_installers = 4,
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"clangd",
				"pyright",
				"ruff",
				"html",
				"cssls",
				"ts_ls",
				"gopls",
				"nginx_language_server",
				"jsonls",
			},
		},
	},
	"jay-babu/mason-nvim-dap.nvim",
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("plugins.config.lsp")
		end,
	},
	
	-- JSON schema 支持 (2025年推荐)
	{
		"b0o/schemastore.nvim",
		lazy = true,
	},
	{
		"Pocco81/auto-save.nvim",
		config = function()
			require("plugins.config.autosave")
		end,
	},

	{
		"antosha417/nvim-lsp-file-operations",
		event = "LspAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-tree.lua",
		},
		--config = function()
		--require("lsp-file-operations").setup()
		--end,
	},

	-- quick move
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	-- 现代化移动插件 (2025年推荐，替代leap+flit)
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {
			-- 搜索配置
			search = {
				-- 搜索时向前和向后查找
				forward = true,
				-- 多窗口搜索
				multi_window = true,
				-- 环绕搜索
				wrap = true,
				-- 增量搜索
				incremental = false,
			},
			-- 跳转配置
			jump = {
				-- 自动跳转到唯一匹配
				jumplist = true,
				-- 跳转位置
				pos = "start", -- "start", "end", "range"
				-- 历史记录
				history = false,
				-- 寄存器
				register = false,
			},
			-- 标签配置
			label = {
				-- 标签字符
				alphabet = "abcdefghijklmnopqrstuvwxyz",
				-- 大写字符处理
				uppercase = true,
				-- 彩虹标签
				rainbow = {
					enabled = false,
					-- 仅在深色背景下启用
					shade = 5,
				},
			},
			-- 高亮配置
			highlight = {
				-- 高亮匹配
				matches = true,
				-- 背景高亮
				backdrop = true,
				-- 组
				groups = {
					match = "FlashMatch",
					current = "FlashCurrent",
					backdrop = "FlashBackdrop",
					label = "FlashLabel",
				},
			},
			-- 模式配置
			modes = {
				-- 字符模式 (类似 f, F, t, T)
				char = {
					enabled = true,
					-- 按键映射
					keys = { "f", "F", "t", "T", ";", "," },
					-- 搜索字符
					search = { wrap = false },
					-- 高亮
					highlight = { backdrop = true },
					-- 跳转
					jump = { register = false },
				},
				-- 搜索模式 (类似 /, ?)
				search = {
					enabled = true,
					-- 高亮
					highlight = { backdrop = false },
					-- 跳转
					jump = { history = true, register = true, nohlsearch = true },
					-- 搜索
					search = {
						-- 模式
						mode = "exact",
						-- 增量搜索
						incremental = true,
					},
				},
				-- Treesitter 搜索
				treesitter = {
					labels = "abcdefghijklmnopqrstuvwxyz",
					jump = { pos = "range" },
					search = { incremental = false },
					label = { before = true, after = true, style = "inline" },
					highlight = {
						backdrop = false,
						matches = false,
					},
				},
			},
		},
		-- stylua: ignore
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
			{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		-- cmd = 'Telescope',
		config = function()
			require("plugins.config.telescope")
		end,
	},
	"nvim-telescope/telescope-live-grep-args.nvim",
	"nvim-telescope/telescope-ui-select.nvim",

	-- tree syntc
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("plugins.config.treesitter")
			-- 确保 latex 语法高亮
			local ts = require("nvim-treesitter.configs")
			ts.setup({
				ensure_installed = { "latex" },
			})
		end,
	},
	"nvim-treesitter/nvim-treesitter-context",

	-- cmp
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		config = function()
			require("plugins.config.cmp")
		end,
	},
	"onsails/lspkind.nvim",

	-- 代码段提示
	{

		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		run = "make install_jsregexp",
		dependencies = {
			"saadparwaiz1/cmp_luasnip", -- Snippets source for nvim-cmp
			"rafamadriz/friendly-snippets", --代码段合集
		},
		config = function()
			require("plugins.config.luasnip")
		end,
	},

	-- status line
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("plugins.config.lualine")
		end,
	},

	-- file explorer
	{
		"nvim-tree/nvim-tree.lua",
		cmd = {
			"NvimTreeOpen",
			"NvimTreeClose",
			"NvimTreeToggle",
			"NvimTreeFindFile",
			"NvimTreeFindFileToggle",
		},
		config = function()
			require("plugins.config.nvim-tree")
		end,
	},

	-- Git 工具 (保留两个选择)
	"tpope/vim-fugitive", -- 传统Git命令行界面
	{
		"NeogitOrg/neogit", -- 现代化Git界面
		dependencies = {
			"nvim-lua/plenary.nvim",         -- required
			"sindrets/diffview.nvim",        -- optional - Diff integration
			"nvim-telescope/telescope.nvim", -- optional
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
		},
		config = function()
			require("plugins.config.neogit")
		end,
	},
	{
		"wintermute-cell/gitignore.nvim",
		cmd = { "Gitignore" },
		config = function()
			require("gitignore")
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit",
		requires = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("plugins.config.lazygit").setup()
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

	-- indent line
	{
		"lukas-reineke/indent-blankline.nvim",
		version = "v3.8.2",

		event = "BufRead",
		config = function()
			require("plugins.config.indent_blankline")
		end,
	},

	-- auto pairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},
	-- auto tag for html
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	{
		"andymass/vim-matchup",
		config = function()
			vim.g.matchup_matchparen_enabled = 0
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	-- auto end
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

	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},

	-- which key
	{
		"folke/which-key.nvim",
		config = function()
			require("plugins.config.which-key")
		end,
	},

	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("plugins.config.toggleterm")
		end,
	},

	{

		"iamcco/markdown-preview.nvim",
		ft = "markdown",
		config = function()
			vim.fn["mkdp#util#install"]()
		end,
	},

	--debug for python
	{
		"mfussenegger/nvim-dap",
		-- cmd = { "Telescope" },
		config = function()
			require("plugins.dap")
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
	},
	"mfussenegger/nvim-dap-python",
	"nvim-telescope/telescope-dap.nvim",
	"theHamsta/nvim-dap-virtual-text",
	{
		"Weissle/persistent-breakpoints.nvim",
		cmd = "PersistentBreakpointsToggle",
		config = function()
			require("persistent-breakpoints").setup({
				load_breakpoints_event = { "BufReadPost" },
			})
		end,
	},

	-- folding
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		config = function()
			require("plugins.config.ufo")
		end,
	},

	-- theme for neovim
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		-- 'NLKNguyen/papercolor-theme',
		--config = function()
		--vim.o.background = "light" -- or "dark" for light mode
		--vim.cmd("colorscheme PaperColor")
		--end
	},
	"NLKNguyen/papercolor-theme",
	"morhetz/gruvbox",
	"altercation/vim-colors-solarized",

	-- go to small window
	{
		"rmagatti/goto-preview",
		event = "LspAttach",
		config = function()
			require("plugins.config.goto-preview")
		end,
	},

	-- quickfix window
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
		config = function()
			require("plugins.config.bqf")
		end,
	},

	-- optional
	--"junegunn/fzf",
	{
		"ibhagwan/fzf-lua",
		-- cmd = { 'FzfLua' },
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- calling `setup` is optional for customization
			require("plugins.config.fzf")
		end,
	},
	-- lazy.nvim

	-- habit
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {},
	},

	-- diff
	{
		"sindrets/diffview.nvim",
		config = function()
			require("diffview").setup({
				enhanced_diff_hl = true,
				view = {
					default = {
						-- Config for changed files, and staged files in diff views.
						layout = "diff2_vertical",
						disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
						winbar_info = false, -- See |diffview-config-view.x.winbar_info|
					},
					merge_tool = {
						layout = "diff3_mixed",
					},
				},
			})
		end,
	},
	-- 现代化启动屏 (2025年推荐，替代alpha-nvim)
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.dashboard")
		end,
	},

	-- file browser

	{
		"nvim-telescope/telescope-file-browser.nvim",
		-- cmd = 'Telescope',
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
	--chatgpt
	-- {
	--     "jackMort/ChatGPT.nvim",
	--     event = "VeryLazy",
	--     dependencies = {
	--         "MunifTanjim/nui.nvim",
	--         "nvim-lua/plenary.nvim",
	--         "folke/trouble.nvim",
	--         "nvim-telescope/telescope.nvim"
	--     }
	-- },

	-- unit test
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			-- "nvim-treesitter/nvim-treesitter",
		},
		cmd = { "NeotestRun", "NeotestSummary" },
		config = function()
			require("plugins.config.neotest")
		end,
	},
	"nvim-neotest/neotest-python",
	{
		"andythigpen/nvim-coverage",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("plugins.config.coverage")
		end,
		-- Optional: needed for PHP when using the cobertura parser
		rocks = { "lua-xmlreader" },
		--config = function()
		--require("coverage").setup()
		--end,
	},
	-- 移除了 nvim-colorizer.lua (已停止维护且使用废弃API)
	--project manager
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				manual_mode = true,
				scope_chdir = "global",
			})
		end,
	},
	-- gitlab
	-- {
	--     "harrisoncramer/gitlab.nvim",
	--     dependencies = {
	--         "MunifTanjim/nui.nvim",
	--         "nvim-lua/plenary.nvim",
	--         "sindrets/diffview.nvim",
	--         "stevearc/dressing.nvim",     -- Recommended but not required. Better UI for pickers.
	--         "nvim-tree/nvim-web-devicons" -- Recommended but not required. Icons in discussion tree.
	--     },
	--     enabled = true,
	--     build = function() require("gitlab.server").build(true) end, -- Builds the Go binary
	--     config = function()
	--         require("gitlab").setup({
	--             debug = {
	--                 go_request = true,
	--                 go_response = true,
	--             },
	--         })
	--     end,
	-- },

	-- {
	-- 	"nvimdev/lspsaga.nvim",
	-- 	event = "LspAttach",
	-- 	config = function()
	-- 		require("plugins.config.lspsaga")
	-- 	end,
	-- 	dependencies = {
	-- 		-- "nvim-treesitter/nvim-treesitter", -- optional
	-- 		"nvim-tree/nvim-web-devicons", -- optional
	-- 	},
	-- },
	{
		"michaelb/sniprun",
		branch = "master",

		build = "sh install.sh",
		cmd = "SnipRun",
		-- do 'sh install.sh 1' if you want to force compile locally
		-- (instead of fetching a binary from the github release). Requires Rust >= 1.65

		config = function()
			require("sniprun").setup({
				-- your options
			})
		end,
	},
	-- 代码格式化 (2025年现代化配置)
	{
		'stevearc/conform.nvim',
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { { "prettierd", "prettier" } },
				typescript = { { "prettierd", "prettier" } },
				javascriptreact = { { "prettierd", "prettier" } },
				typescriptreact = { { "prettierd", "prettier" } },
				vue = { { "prettierd", "prettier" } },
				css = { { "prettierd", "prettier" } },
				scss = { { "prettierd", "prettier" } },
				html = { { "prettierd", "prettier" } },
				json = { { "prettierd", "prettier" } },
				jsonc = { { "prettierd", "prettier" } },
				yaml = { { "prettierd", "prettier" } },
				markdown = { { "prettierd", "prettier" } },
				go = { "goimports", "gofmt" },
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
			-- 设置格式化表达式
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
	-- {
	--     'pwntester/octo.nvim',
	--     requires = {
	--         'nvim-lua/plenary.nvim',
	--         'nvim-telescope/telescope.nvim',
	--         -- OR 'ibhagwan/fzf-lua',
	--         'nvim-tree/nvim-web-devicons',
	--     },
	--     --config = function()
	--     --require "octo".setup()
	--     --end
	-- },
	-- image show
	{
		-- "edluffy/hologram.nvim",
		--config = function()
		--require('hologram').setup {
		--auto_display = true -- WIP automatic markdown image display, may be prone to breaking
		--}
		--end
	},
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
		event = { "User KittyScrollbackLaunch" },
		-- version = '*', -- latest stable version, may have breaking changes if major version changed
		-- version = '^4.0.0', -- pin major version, include fixes and features that do not have breaking changes
		config = function()
			require("kitty-scrollback").setup({
				on_attach = function()
					vim.g.kitty_scrollback_enabled = true
				end,
			})
		end,
	},
	{
		"willothy/flatten.nvim",
		config = function()
			require("flatten").setup({
				window = {
					open = "vsplit",
				},
			})
		end,
		-- or pass configuration with
		-- opts = {  }
		-- Ensure that it runs first to minimize delay when opening file from terminal
		lazy = false,
		priority = 1001,
	},
	-- zen
	{
		"folke/zen-mode.nvim",
	},
	{
		"AckslD/nvim-neoclip.lua",
		dependencies = {
			-- you'll need at least one of these
			-- {'nvim-telescope/telescope.nvim'},
			-- {'ibhagwan/fzf-lua'},
		},
		config = function()
			require("neoclip").setup()
		end,
	},
	-- ui
	{
		"stevearc/dressing.nvim",
		opts = {},
	},
	{
		keys = {
			{
				"<leader>arr",
				"<cmd>CellularAutomaton make_it_rain<cr>",
				desc = "Rain",
			},
			{
				"<leader>arg",
				"<cmd>CellularAutomaton game_of_life<cr>",
				desc = "Game",
			},
			{
				"<leader>ars",
				"<cmd>CellularAutomaton scramble<cr>",
				desc = "Game",
			},
		},
		"eandrju/cellular-automaton.nvim",
	},
	-- task
	{
		"stevearc/overseer.nvim",
		config = function()
			require("plugins.config.overseer")
		end,
	},
	-- "uga-rosa/translate.nvim",

	{
		"rest-nvim/rest.nvim",
	},
	{
		"matbme/JABS.nvim",
		config = function()
			require("jabs").setup({})
		end,
	},

	-- undo tree
	"mbbill/undotree",
	-- python venv
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
		config = function()
			require("venv-selector").setup({
				name = ".venv",
			})
		end,
		keys = {
			{ "<leader>vvs", "<cmd>VenvSelect<cr>" },
			{ "<leader>vvc", "<cmd>VenvSelectCached<cr>" },
			{ "<leader>vvu", "<cmd>VenvSelectCurrent<cr>" },
		},
	},

	-- icons
	{
		"nvim-tree/nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({
				override = {
					default_icon = {
						icon = "��",
						color = "#6d8086",
						name = "Default",
					},
				},
				strict = true,
			})
		end,
	},
	-- remote nvim
	{
		"amitds1997/remote-nvim.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("remote-nvim").setup({
				remote = {
					copy_dirs = {
						config = {
							base = vim.fn.stdpath("config"),
							dirs = "*",
							compression = { enabled = false },
						},
						data = {
							base = vim.fn.stdpath("data"),
							dirs = { "lazy" },
							compression = { enabled = true },
						},
					},
				},
				offline_mode = {
					enabled = false,
					no_github = false,
				},
			})
		end,
	},
	-- csv viewer
	{
		"hat0uma/csvview.nvim",
		---@module "csvview"
		---@type CsvView.Options
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				-- Text objects for selecting fields
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				-- Excel-like navigation:
				-- Use <Tab> and <S-Tab> to move horizontally between fields.
				-- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
				-- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},
	{
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({
				render = "background", -- or 'foreground' or 'virtual'
				enable_named_colors = true,
				enable_tailwind = true,
			})
		end,
	},
	{
		"lervag/vimtex",
		ft = { "tex" },
		config = function()
			vim.g.vimtex_view_method = "skim"
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_quickfix_mode = 0
			vim.g.vimtex_view_skim_sync = 1
			vim.g.vimtex_view_skim_activate = 1
			vim.g.vimtex_compiler_latexmk_engines = {
				_ = "-xelatex",
			}
			-- 中文支持：用 xelatex 编译
			vim.g.vimtex_compiler_latexmk = {
				build_dir = '',
				callback = 1,
				continuous = 1,
				executable = "latexmk",
				options = {
					"-file-line-error",
					"-synctex=1",
					"-interaction=nonstopmode",
				},
			}
			-- 取消默认快捷键
			vim.g.vimtex_mappings_enabled = 0
			-- 自定义 <leader>l 开头快捷键
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "tex",
				callback = function()
					local opts = { buffer = true, noremap = true, silent = true, desc = "Vimtex" }
					vim.keymap.set("n", "<leader>tc", "<Plug>(vimtex-clean)", opts)
					vim.keymap.set("n", "<leader>tl", "<Plug>(vimtex-compile)", opts)
					vim.keymap.set("n", "<leader>tv", "<Plug>(vimtex-view)", opts)
					vim.keymap.set("n", "<leader>te", "<Plug>(vimtex-errors)", vim.tbl_extend("force", opts, { desc = "LaTeX 查看错误" }))
					vim.keymap.set("n", "<leader>ts", "<Plug>(vimtex-status)", vim.tbl_extend("force", opts, { desc = "LaTeX 编译状态" }))
					vim.keymap.set("n", "<leader>tk", "<Plug>(vimtex-stop)", vim.tbl_extend("force", opts, { desc = "LaTeX 停止编译" }))
					vim.keymap.set("n", "<leader>tt", "<Plug>(vimtex-compile-output)", vim.tbl_extend("force", opts, { desc = "LaTeX 编译输出" }))
					vim.keymap.set("n", "<leader>tf", "<Plug>(vimtex-reload)", vim.tbl_extend("force", opts, { desc = "LaTeX 重新加载" }))
					vim.keymap.set("n", "<leader>tj", "<Plug>(vimtex-next-error)", vim.tbl_extend("force", opts, { desc = "LaTeX 下一个错误" }))
					vim.keymap.set("n", "<leader>th", "<Plug>(vimtex-prev-error)", vim.tbl_extend("force", opts, { desc = "LaTeX 上一个错误" }))
					vim.keymap.set("n", "<leader>tp", "<Plug>(vimtex-toggle-main)", vim.tbl_extend("force", opts, { desc = "LaTeX 切换主文件" }))
				end,
			})
		end,
	},
	{
		"kdheepak/cmp-latex-symbols",
		ft = { "tex" },
	},
}
