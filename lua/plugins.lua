-- Only required if you have packer configured as `opt`
local packer = require('packer')
vim.cmd [[packadd packer.nvim]]

-- return packer.startup(function(use)
return packer.startup(function()
		-- manage itself
		use 'wbthomason/packer.nvim'

		use { 'neovim/nvim-lspconfig', config = function() require'lspconfig'.pyright.setup{} end }

		use "Pocco81/AutoSave.nvim"
		-- markdown
		use {"ellisonleao/glow.nvim", run = "GlowInstall"}
		
		-- quick move
		use 'easymotion/vim-easymotion'

		-- recent open file
		use 'mhinz/vim-startify'

		use {
		  'nvim-telescope/telescope.nvim',
		  requires = { {'nvim-lua/plenary.nvim'} }
		}

		use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
end)

