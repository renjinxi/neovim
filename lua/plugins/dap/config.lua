local mason_nvim_dap_exists, mason_nvim_dap = pcall(require, "mason-nvim-dap")
if not mason_nvim_dap_exists then
	return
end

mason_nvim_dap.setup({
	ensure_installed = { "python", "codelldb", "js" },
	handlers = {
		function(config)
			-- all sources with no handler get passed here

			-- Keep original functionality
			require("mason-nvim-dap").default_setup(config)
		end,
	},
})

local dap_text_exists, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
if not dap_text_exists then
	return
end
dap_virtual_text.setup()
