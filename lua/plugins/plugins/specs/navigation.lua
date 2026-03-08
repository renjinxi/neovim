return {
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
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = function()
			return require("plugins.config.flash")
		end,
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.config.harpoon")
		end,
	},
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
	{
		"natecraddock/workspaces.nvim",
		config = function()
			require("plugins.config.workspaces")
		end,
	},
	{
		"jedrzejboczar/possession.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.config.possession")
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				manual_mode = true,
				scope_chdir = "global",
			})
		end,
	},
}
