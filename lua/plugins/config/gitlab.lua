-- GitLab.nvim 配置
-- 从 glab-cli 配置读取 token

local gitlab = require("gitlab")

local GITLAB_URL = "https://g.ktvsky.com"

-- 读取 glab 配置获取 token，返回 token, gitlab_url, err
local function get_gitlab_auth()
	local config_path = vim.fn.expand("~/.config/glab-cli/config.yml")
	if vim.fn.filereadable(config_path) == 1 then
		local content = vim.fn.readfile(config_path)
		local in_host_section = false
		for _, line in ipairs(content) do
			-- 检查是否进入 g.ktvsky.com 配置段
			if line:match("^%s+g%.ktvsky%.com:") then
				in_host_section = true
			elseif in_host_section and line:match("^%s+%S") and not line:match("^%s+token:") then
				-- 离开当前 host 配置段
				in_host_section = false
			end
			-- 在正确的 host 段内匹配 token
			if in_host_section then
				local token = line:match("^%s+token:%s*(.+)$")
				if token then
					return token, GITLAB_URL, nil
				end
			end
		end
	end
	local token = vim.env.GITLAB_TOKEN
	if token then
		return token, GITLAB_URL, nil
	end
	return nil, nil, "No GitLab token found"
end

gitlab.setup({
	-- 认证 provider (返回 token, gitlab_url, err)
	auth_provider = get_gitlab_auth,
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
