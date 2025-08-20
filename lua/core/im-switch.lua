-- 简单的输入法切换模块
local M = {}

-- 配置
local config = {
	default_im = "com.apple.keylayout.ABC",
	saved_im = nil, -- 保存的输入法状态
	insert_im = nil, -- 记录进入插入模式时设置的输入法
	macism_cmd = "macism",
}

-- 获取当前输入法
local function get_current_im()
	local handle = io.popen(config.macism_cmd)
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result:gsub("%s+", "")
	end
	return nil
end

-- 设置输入法
local function set_im(im_id)
	if im_id and im_id ~= "" then
		os.execute(config.macism_cmd .. " " .. im_id)
	end
end

-- 记录当前输入法状态（在用户可能手动切换输入法后）
function M.record_current_im()
	local current = get_current_im()
	if current and current ~= config.default_im then
		config.saved_im = current
	end
end

-- 进入插入模式时，恢复之前保存的输入法
function M.on_insert_enter()
	if config.saved_im and config.saved_im ~= config.default_im then
		set_im(config.saved_im)
	end
end

-- 离开插入模式时，切换到默认输入法
function M.on_insert_leave()
	-- 在切换前记录当前状态
	local current = get_current_im()
	if current and current ~= config.default_im then
		config.saved_im = current
	end
	
	-- 切换到默认输入法
	set_im(config.default_im)
end

-- 检测是否在远程环境
local function is_remote()
	return vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
end

-- 设置自动命令
function M.setup()
	-- 如果是远程环境，跳过设置
	if is_remote() then
		print("检测到远程环境，跳过输入法自动切换")
		-- 可选：在远程环境设置手动切换快捷键
		-- vim.keymap.set('n', '<leader>ie', function() 
		--   vim.fn.system('ssh local-host "~/.config/nvim/scripts/ssh-im.sh set com.apple.keylayout.ABC"')
		-- end, {desc = "切换到英文输入法"})
		return
	end
	
	local augroup = vim.api.nvim_create_augroup("InputMethodSwitch", { clear = true })
	
	-- 进入插入模式时恢复输入法
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		callback = M.on_insert_enter,
	})
	
	-- 离开插入模式时保存输入法并切换到默认
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		callback = M.on_insert_leave,
	})
	
	-- 在普通模式下用户可能手动切换输入法，用 CursorMoved 检测
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = augroup,
		callback = function()
			-- 只在普通模式记录
			if vim.api.nvim_get_mode().mode == "n" then
				M.record_current_im()
			end
		end,
	})
	
	-- 只在启动时设置默认输入法
	vim.api.nvim_create_autocmd("VimEnter", {
		group = augroup,
		callback = function()
			set_im(config.default_im)
		end,
	})
end

return M