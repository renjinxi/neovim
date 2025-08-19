local M = {}

function M.setup()
	-- 获取 possession 配置模块
	local possession_config = require("plugins.config.possession")
	
	-- 定义 which-key 组和快捷键 (使用 <leader>m 前缀 - session Memory/Management)
	local which_key_mappings = {
		{ "<leader>m", group = "Sessions", nowait = false, remap = false },
		
		-- 基本会话操作
		{ "<leader>ms", "<cmd>PossessionSave<cr>", desc = "Save session", nowait = false, remap = false },
		{ "<leader>ml", "<cmd>PossessionLoad<cr>", desc = "Load session", nowait = false, remap = false },
		{ "<leader>md", "<cmd>PossessionDelete<cr>", desc = "Delete session", nowait = false, remap = false },
		{ "<leader>mc", "<cmd>PossessionClose<cr>", desc = "Close session", nowait = false, remap = false },
		{ "<leader>mh", "<cmd>PossessionList<cr>", desc = "List sessions", nowait = false, remap = false },
		{ "<leader>mr", "<cmd>PossessionRename<cr>", desc = "Rename session", nowait = false, remap = false },
		{ "<leader>mi", "<cmd>PossessionShow<cr>", desc = "Show current session", nowait = false, remap = false },
		
		-- 工作区特定的会话操作
		{ "<leader>mw", function()
			possession_config.save_workspace_session()
		end, desc = "Save workspace session", nowait = false, remap = false },
		
		{ "<leader>mW", function()
			possession_config.load_workspace_session()
		end, desc = "Load workspace session", nowait = false, remap = false },
		
		{ "<leader>mD", function()
			possession_config.delete_workspace_session()
		end, desc = "Delete workspace session", nowait = false, remap = false },
		
		-- 会话选择器
		{ "<leader>mm", function()
			possession_config.list_workspace_sessions()
		end, desc = "Select session", nowait = false, remap = false },
		
		-- Telescope 集成 (如果可用)
		{ "<leader>mt", function()
			if pcall(require, "telescope") then
				vim.cmd("Telescope possession")
			else
				vim.cmd("PossessionList")
			end
		end, desc = "Telescope sessions", nowait = false, remap = false },
	}

	-- 注册快捷键到 which-key
	require("which-key").add(which_key_mappings)
end

return M