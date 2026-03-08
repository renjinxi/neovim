local specs = {
	"folke/lazy.nvim",
}

local groups = {
	"plugins.plugins.specs.lsp",
	"plugins.plugins.specs.navigation",
	"plugins.plugins.specs.git",
	"plugins.plugins.specs.debug",
	"plugins.plugins.specs.ui",
	"plugins.plugins.specs.workflow",
	"plugins.plugins.specs.languages",
}

for _, group in ipairs(groups) do
	vim.list_extend(specs, require(group))
end

return specs
