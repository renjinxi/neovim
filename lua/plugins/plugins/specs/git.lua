return {
	"tpope/vim-fugitive",
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = "Neogit",
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
		"sindrets/diffview.nvim",
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
}
