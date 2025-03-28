local M = {}

-- 定义需要重载的模块模式
local MODULE_PATTERNS = {
	"^core%.",
	"^config%.",
	"^plugins%.",
	"^lsp%.",
}

-- 定义核心配置模块
local CORE_MODULES = {
	"core.options",
	"core.autocmds",
	"core.keymaps",
	"core.theme",
	"plugins.lsp.init",
}

-- 清除模块缓存
local function clear_module_cache()
	local cleared = 0
	for name, _ in pairs(package.loaded) do
		for _, pattern in ipairs(MODULE_PATTERNS) do
			if name:match(pattern) then
				package.loaded[name] = nil
				cleared = cleared + 1
			end
		end
	end
	return cleared
end

-- 重新加载核心模块
local function reload_core_modules()
	local success = true
	local errors = {}

	for _, module in ipairs(CORE_MODULES) do
		local ok, err = pcall(require, module)
		if not ok then
			success = false
			table.insert(errors, string.format("加载模块 %s 失败: %s", module, err))
		end
	end

	return success, errors
end

-- 同步插件
local function sync_plugins()
	local ok, lazy = pcall(require, "lazy")
	if not ok then
		return false, "无法加载 lazy.nvim"
	end

	local success = true
	local err = nil

	pcall(function()
		lazy.sync()
	end)

	return success, err
end

function M.reload_config()
	local start_time = vim.loop.now()

	-- 清除模块缓存
	local cleared_count = clear_module_cache()
	vim.notify(string.format("已清除 %d 个模块缓存", cleared_count), vim.log.levels.INFO)

	-- 重新加载核心模块
	local success, errors = reload_core_modules()
	if not success then
		vim.notify("重载核心模块失败:\n" .. table.concat(errors, "\n"), vim.log.levels.ERROR)
		return false
	end

	-- 同步插件
	local plugin_success, plugin_err = sync_plugins()
	if not plugin_success then
		vim.notify("同步插件失败: " .. plugin_err, vim.log.levels.ERROR)
		return false
	end

	-- 计算耗时
	local end_time = vim.loop.now()
	local duration = (end_time - start_time) / 1000 -- 转换为毫秒

	-- 通知成功
	vim.notify(string.format("配置重载完成，耗时: %.2fms", duration), vim.log.levels.INFO)
	return true
end

return M

