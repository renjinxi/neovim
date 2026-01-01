-- GitLab.nvim 配置
-- 从 glab-cli 配置读取 token

local gitlab = require("gitlab")

-- 读取 glab 配置获取 token
local function get_gitlab_token()
	local config_path = vim.fn.expand("~/.config/glab-cli/config.yml")
	if vim.fn.filereadable(config_path) == 1 then
		local content = vim.fn.readfile(config_path)
		for _, line in ipairs(content) do
			local token = line:match("^%s*token:%s*(.+)$")
			if token then
				return token
			end
		end
	end
	return vim.env.GITLAB_TOKEN
end

gitlab.setup({
	-- GitLab 地址 (自建实例)
	gitlab_url = "https://g.ktvsky.com",
	-- 认证 token
	auth_provider = get_gitlab_token,
	-- 调试模式
	debug = { go_request = false, go_response = false },
	-- 附件保存位置
	attachment_dir = vim.fn.expand("~/.local/share/nvim/gitlab_attachments"),
	-- 弹窗配置
	popup = {
		exit = "<Esc>",
		perform_action = "<leader>s",
		perform_linewise_action = "<leader>l",
	},
	-- 讨论树配置
	discussion_tree = {
		auto_open = true,
		switch_view = "S",
		default_view = "discussions",
		toggle_resolved = "r",
		jump_to_file = "o",
		jump_to_reviewer = "m",
		edit_comment = "e",
		delete_comment = "dd",
		reply = "R",
		toggle_node = "t",
	},
	-- MR 信息配置
	info = {
		horizontal = false,
		fields = {
			"author",
			"created_at",
			"updated_at",
			"merge_status",
			"draft",
			"conflicts",
			"assignees",
			"reviewers",
			"pipeline",
			"branch",
			"labels",
		},
	},
	-- Pipeline 配置
	pipeline = {
		created = "",
		pending = "",
		preparing = "",
		scheduled = "",
		running = "",
		canceled = "",
		skipped = "",
		success = "✓",
		failed = "",
	},
})
