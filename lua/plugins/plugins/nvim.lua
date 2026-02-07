return {
	-- ================================
	-- 核心插件管理
	-- ================================
	"folke/lazy.nvim",

	-- ================================
	-- LSP 和语言服务器 (2025年现代化配置)
	-- ================================
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		config = function()
			require("plugins.config.mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		-- 2025年版本：配置移动到独立文件，支持新的 automatic_enable 特性
		config = false, -- 在mason配置中统一处理
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- 格式化工具
					"prettierd", -- 前端代码格式化
					"eslint_d", -- ESLint daemon (更快的 linting)
					"goimports",
					"google-java-format", -- Java 格式化
					"ktlint", -- Kotlin 格式化和 linting
					-- Java/Android 开发工具
					"java-debug-adapter", -- Java 调试器
					"java-test", -- Java 测试
				},
				auto_update = false,
				run_on_start = true,
			})
		end,
	},
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
	{
		"b0o/schemastore.nvim", -- JSON schema 支持
		lazy = true,
	},
	{
		"antosha417/nvim-lsp-file-operations",
		event = "LspAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-tree.lua",
		},
	},
	{
		"rmagatti/goto-preview", -- LSP 预览窗口
		event = "LspAttach",
		config = function()
			local post_open_hook = function(_, win)
				-- vim.api.nvim_win_set_option(win, "winhighlight", "Normal:")
				vim.api.nvim_set_option_value("winhighlight", "Normal:", { win = win })
			end

			require("goto-preview").setup({
				post_open_hook = post_open_hook,
			})
		end,
	},
	{
		"mfussenegger/nvim-jdtls", -- Java LSP 增强插件
		ft = { "java", "kotlin" },
		dependencies = {
			"mfussenegger/nvim-dap", -- Java 调试需要 DAP
		},
	},

	-- ================================
	-- 代码补全和代码片段
	-- ================================
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
	{
		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		run = "make install_jsregexp",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("plugins.config.luasnip")
		end,
	},

	-- ================================
	-- 语法高亮和解析
	-- ================================
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("plugins.config.treesitter")
		end,
	},
	"nvim-treesitter/nvim-treesitter-context",

	-- ================================
	-- 搜索和导航
	-- ================================
	{
		"nvim-telescope/telescope.nvim",
		config = function()
			require("plugins.config.telescope")
		end,
	},
	"nvim-telescope/telescope-live-grep-args.nvim",
	"nvim-telescope/telescope-ui-select.nvim",
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
	{
		"princejoogie/dir-telescope.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.fzf")
		end,
	},
	{
		"folke/flash.nvim", -- 现代化移动插件 (替代leap+flit)
		event = "VeryLazy",
		opts = function()
			return require("plugins.config.flash")
		end,
		-- keys 已迁移到 keymaps/all.lua
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.config.harpoon")
		end,
		-- keys 在 keymaps/all.lua 中定义
	},

	-- ================================
	-- 文件管理和浏览
	-- ================================
	{
		"nvim-tree/nvim-tree.lua",
		cmd = {
			"NvimTreeOpen",
			"NvimTreeClose",
			"NvimTreeToggle",
			"NvimTreeFindFile",
			"NvimTreeFindFileToggle",
		},
		-- keys 已迁移到 keymaps/all.lua
		config = function()
			require("plugins.config.nvim-tree")
		end,
	},

	-- 多项目工作区管理
	{
		"natecraddock/workspaces.nvim",
		config = function()
			require("plugins.config.workspaces")
		end,
	},

	-- 会话持久化管理 - 专门为多项目设计
	{
		"jedrzejboczar/possession.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.config.possession")
		end,
	},

	{
		"ahmedkhalf/project.nvim", -- 项目管理 (保留，与 workspaces 配合使用)
		config = function()
			require("project_nvim").setup({
				manual_mode = true,
				scope_chdir = "global",
			})
		end,
	},

	-- ================================
	-- Git 集成
	-- ================================
	"tpope/vim-fugitive", -- 传统Git命令行界面
	{
		"NeogitOrg/neogit", -- 现代化Git界面
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = "Neogit",
		-- keys 已迁移到 keymaps/all.lua
		config = function()
			require("plugins.config.neogit")
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("plugins.config.gitsigns")
		end,
	},
	{
		"sindrets/diffview.nvim", -- Git差异查看
		config = function()
			require("plugins.config.diffview")
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
		"ThePrimeagen/git-worktree.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("plugins.config.git-worktree")
		end,
	},

	-- ================================
	-- 代码编辑增强
	-- ================================
	{
		"windwp/nvim-autopairs", -- 自动配对
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},
	{
		"windwp/nvim-ts-autotag", -- HTML标签自动配对
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"kylechui/nvim-surround", -- 包围编辑
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"andymass/vim-matchup", -- 增强的匹配
		config = function()
			vim.g.matchup_matchparen_enabled = 0
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	{
		"numToStr/Comment.nvim", -- 快速注释
		opts = {},
		lazy = false,
	},
	{
		"kevinhwang91/nvim-ufo", -- 代码折叠
		dependencies = "kevinhwang91/promise-async",
		config = function()
			require("plugins.config.ufo")
		end,
	},

	-- ================================
	-- 代码格式化和检查
	-- ================================
	{
		"stevearc/conform.nvim", -- 代码格式化 (2025年现代化配置)
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("plugins.config.conform")
		end,
	},
	{
		"folke/trouble.nvim", -- 诊断列表
		config = function()
			local config = require("plugins.config.trouble")
			require("trouble").setup(config.opts)
		end,
		cmd = function()
			return require("plugins.config.trouble").cmd
		end,
		keys = function()
			return require("plugins.config.trouble").keys
		end,
	},

	-- ================================
	-- 调试工具
	-- ================================
	"jay-babu/mason-nvim-dap.nvim",
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("plugins.dap")
		end,
	},
	"rcarriga/nvim-dap-ui",
	"mfussenegger/nvim-dap-python",
	{
		"leoluz/nvim-dap-go",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			require("dap-go").setup()
		end,
	},
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

	-- ================================
	-- 测试工具
	-- ================================
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
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
		rocks = { "lua-xmlreader" },
	},

	-- ================================
	-- UI 和主题
	-- ================================
	-- {
	-- 	"nvim-lualine/lualine.nvim", -- 状态栏
	-- 	config = function()
	-- 		require("plugins.config.lualine")
	-- 	end,
	-- },
	{
		"rebelot/heirline.nvim", -- 状态栏
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.heirline")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim", -- 缩进线
		version = "v3.8.2",
		event = "BufRead",
		config = function()
			require("ibl").setup({
				indent = { char = "¦" },
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons", -- 图标
		config = function()
			require("nvim-web-devicons").setup({
				override = {
					default_icon = {
						icon = "",
						color = "#6d8086",
						name = "Default",
					},
				},
				strict = true,
			})
		end,
	},
	{
		"nvimdev/dashboard-nvim", -- 启动屏 (2025年推荐，替代alpha-nvim)
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.dashboard")
		end,
	},
	{
		"stevearc/dressing.nvim", -- UI 增强
		opts = {},
	},
	{
		"brenoprata10/nvim-highlight-colors", -- 颜色高亮
		config = function()
			require("nvim-highlight-colors").setup({
				render = "background",
				enable_named_colors = true,
				enable_tailwind = true,
			})
		end,
	},

	-- ================================
	-- 主题配色
	-- ================================
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		config = function()
			require("plugins.config.rose-pine")
		end,
	},
	"NLKNguyen/papercolor-theme",
	"morhetz/gruvbox",
	"altercation/vim-colors-solarized",

	-- ================================
	-- 终端和工具集成
	-- ================================
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
		event = { "User KittyScrollbackLaunch" },
		config = function()
			require("kitty-scrollback").setup({
				on_attach = function()
					vim.g.kitty_scrollback_enabled = true
				end,
			})
		end,
	},
	{
		"willothy/flatten.nvim", -- 终端集成
		config = function()
			require("flatten").setup({
				window = {
					open = "vsplit",
				},
			})
		end,
		lazy = false,
		priority = 1001,
	},

	-- ================================
	-- 快捷键和帮助
	-- ================================
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				delay = function(ctx)
					return 600  -- 增加延迟以减少终端输出干扰
				end,
			})
		end,
	},

	-- ================================
	-- 工作流和生产力
	-- ================================
	-- 移除有问题的 im-select 插件，使用自定义输入法切换
	{
		"djoshea/vim-autoread", -- 文件自动重载 - 更及时的外部变化检测
		config = function()
			-- 启用更频繁的检查
			vim.g.autoread_debounce_time = 100 -- 100ms 延迟
		end,
	},
	{
		"Pocco81/auto-save.nvim", -- 自动保存
		config = function()
			require("plugins.config.autosave")
		end,
	},
	{
		"kevinhwang91/nvim-bqf", -- 增强的quickfix
		ft = "qf",
		config = function()
			require("plugins.config.bqf")
		end,
	},
	{
		"stevearc/overseer.nvim", -- 任务管理
		config = function()
			require("plugins.config.overseer")
		end,
	},
	{
		"gbprod/yanky.nvim", -- 剪贴板历史（持久化 + 系统剪贴板 + yank ring）
		dependencies = { "kkharji/sqlite.lua" },
		config = function()
			require("yanky").setup({
				ring = {
					history_length = 100,
					storage = "sqlite",
					sync_with_numbered_registers = true,
				},
				system_clipboard = {
					sync_with_ring = true, -- 系统剪贴板同步到 ring
				},
				highlight = {
					on_put = true,
					on_yank = true,
					timer = 200,
				},
			})
			-- Telescope 集成
			pcall(function()
				require("telescope").load_extension("yank_history")
			end)
		end,
	},
	"mbbill/undotree", -- 撤销树
	{
		"matbme/JABS.nvim", -- 缓冲区管理
		config = function()
			require("jabs").setup({})
		end,
	},

	-- ================================
	-- 特定语言支持
	-- ================================
	-- Python
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
		config = function()
			require("venv-selector").setup({
				name = ".venv",
			})
		end,
		-- keys 已迁移到 keymaps/all.lua
	},
	-- LaTeX
	{
		"lervag/vimtex",
		ft = { "tex" },
		config = function()
			require("plugins.config.vimtex")
		end,
	},
	{
		"kdheepak/cmp-latex-symbols",
		ft = { "tex" },
	},
	-- Markdown
	{
		"iamcco/markdown-preview.nvim",
		ft = "markdown",
		config = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	-- CSV
	{
		"hat0uma/csvview.nvim",
		opts = function()
			return require("plugins.config.csvview")
		end,
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},
	-- REST API
	{
		"rest-nvim/rest.nvim",
		dependencies = {
			"j-hui/fidget.nvim", -- 进度消息显示
		},
		rocks = { "xml2lua", "mimetypes" }, -- luarocks 依赖
		ft = { "http" },
		config = function()
			require("rest-nvim").setup()
		end,
	},

	-- ================================
	-- 数据库客户端
	-- ================================
	{
		"tpope/vim-dadbod", -- 数据库核心
		cmd = { "DB", "DBUI" },
	},
	{
		"kristijanhusak/vim-dadbod-ui", -- 数据库 UI
		dependencies = {
			"tpope/vim-dadbod",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
		end,
	},
	{
		"kristijanhusak/vim-dadbod-completion", -- 数据库补全
		ft = { "sql", "mysql", "plsql" },
		lazy = true,
	},

	-- ================================
	-- GitLab 集成
	-- ================================
	{
		"harrisoncramer/gitlab.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"stevearc/dressing.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		build = function()
			require("gitlab.server").build(true)
		end,
		cmd = { "GitLabToggle", "GitLabOpen" },
		config = function()
			require("plugins.config.gitlab")
		end,
	},

	-- ================================
	-- 远程开发
	-- ================================
	{
		"amitds1997/remote-nvim.nvim",
		branch = "fix/neovim-install-script",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("plugins.config.remote-nvim")
		end,
	},

	-- ================================
	-- 算法练习
	-- ================================
	{
		"kawre/leetcode.nvim",
		build = ":TSUpdate html",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			lang = "python3",
			storage = {
				home = vim.fn.stdpath("data") .. "/leetcode",
				cache = vim.fn.stdpath("cache") .. "/leetcode",
			},
		},
		config = function(_, opts)
			require("leetcode").setup(opts)
		end,
	},

	-- ================================
	-- 娱乐和其他
	-- ================================
	{
		"folke/zen-mode.nvim", -- 专注模式
		config = function()
			require("zen-mode").setup(require("plugins.config.zen-mode"))
		end,
	},
	{
		"m4xshen/hardtime.nvim", -- 习惯培养
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"eandrju/cellular-automaton.nvim", -- 动画效果
		cmd = "CellularAutomaton",
		-- keys 已迁移到 keymaps/all.lua
	},
}
