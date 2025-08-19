local M = {}

function M.setup()
	-- 获取 workspaces 模块
	local workspaces_config = require("plugins.config.workspaces")
	
	local keymap = vim.keymap.set
	local opts = { noremap = true, silent = true }

	-- 定义 which-key 组
	local which_key_mappings = {
		{ "<leader>c", group = "Workspace", nowait = false, remap = false },
		
		-- 项目管理
		{ "<leader>ca", function()
			workspaces_config.add_project_to_workspace()
		end, desc = "Add project to workspace", nowait = false, remap = false },
		
		{ "<leader>cA", function()
			vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
				if path then
					workspaces_config.add_project_to_workspace(vim.fn.expand(path))
				end
			end)
		end, desc = "Add project (specify path)", nowait = false, remap = false },
		
		{ "<leader>cr", function()
			workspaces_config.remove_project_from_workspace()
		end, desc = "Remove project from workspace", nowait = false, remap = false },
		
		{ "<leader>cl", function()
			workspaces_config.list_workspace_projects()
		end, desc = "List workspace projects", nowait = false, remap = false },
		
		{ "<leader>cs", function()
			workspaces_config.switch_project_root()
		end, desc = "Switch project root", nowait = false, remap = false },

		-- 跨项目搜索
		{ "<leader>cf", function()
			workspaces_config.search_all_projects()
		end, desc = "Find files (all projects)", nowait = false, remap = false },
		
		{ "<leader>cF", function()
			workspaces_config.search_all_projects_with_hidden()
		end, desc = "Find files (all projects + hidden)", nowait = false, remap = false },
		
		{ "<leader>cg", function()
			workspaces_config.grep_all_projects()
		end, desc = "Grep (all projects)", nowait = false, remap = false },
		
		{ "<leader>cG", function()
			workspaces_config.grep_all_projects_with_hidden()
		end, desc = "Grep (all projects + hidden)", nowait = false, remap = false },

		-- LSP workspace folders 管理
		{ "<leader>caf", function()
			vim.lsp.buf.add_workspace_folder()
		end, desc = "Add LSP workspace folder", nowait = false, remap = false },
		
		{ "<leader>crf", function()
			vim.lsp.buf.remove_workspace_folder()
		end, desc = "Remove LSP workspace folder", nowait = false, remap = false },
		
		{ "<leader>clf", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, desc = "List LSP workspace folders", nowait = false, remap = false },

		-- Telescope 集成
		{ "<leader>cc", "<cmd>Telescope workspaces<cr>", desc = "Telescope workspaces", nowait = false, remap = false },
		{ "<leader>cp", "<cmd>Telescope workspaces<cr>", desc = "Switch workspace", nowait = false, remap = false },
	}

	-- 注册快捷键到 which-key
	require("which-key").add(which_key_mappings)
end

return M