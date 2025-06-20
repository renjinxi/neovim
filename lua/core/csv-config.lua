local M = {}

-- CSV文件自动配置模块
-- 功能：自动检测CSV/TSV文件并启用CsvView

--- 检查文件是否可能是CSV格式
---@param bufnr number 缓冲区号
---@return boolean
local function is_csv_like_content(bufnr)
	-- 读取前几行来检查内容
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, false)
	if #lines == 0 then
		return false
	end
	
	-- 检查是否有逗号或制表符分隔
	for _, line in ipairs(lines) do
		if line:find(',') or line:find('\t') then
			return true
		end
	end
	
	return false
end

--- 自动启用CSV视图
---@param bufnr number 缓冲区号
function M.auto_enable_csv_view(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	
	-- 检查命令是否存在
	if vim.fn.exists(":CsvViewEnable") ~= 2 then
		return
	end
	
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local ext = vim.fn.fnamemodify(filename, ':e'):lower()
	
	-- 支持的文件扩展名
	local csv_extensions = { 'csv', 'tsv' }
	local is_csv_file = vim.tbl_contains(csv_extensions, ext)
	
	-- 如果不是明显的CSV文件，检查内容
	if not is_csv_file and is_csv_like_content(bufnr) then
		is_csv_file = true
	end
	
	if is_csv_file then
		-- 延迟执行以确保文件完全加载
		vim.defer_fn(function()
			-- 再次检查缓冲区是否仍然有效
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.cmd("CsvViewEnable display_mode=border header_lnum=1")
				
				-- 可选：设置一些CSV友好的选项
				vim.bo[bufnr].wrap = false
				vim.bo[bufnr].scrollopt = 'hor'
			end
		end, 150)
	end
end

--- 设置CSV相关的键绑定
function M.setup_csv_keymaps()
	-- 创建CSV专用的键绑定组
	local csv_group = vim.api.nvim_create_augroup("CsvKeymaps", { clear = true })
	
	vim.api.nvim_create_autocmd("FileType", {
		group = csv_group,
		pattern = "csv",
		callback = function()
			local opts = { buffer = true, silent = true }
			
			-- 快速切换CSV视图
			vim.keymap.set('n', '<leader>ct', '<cmd>CsvViewToggle<cr>', 
				vim.tbl_extend('force', opts, { desc = "切换CSV视图" }))
			
			-- 禁用CSV视图
			vim.keymap.set('n', '<leader>cd', '<cmd>CsvViewDisable<cr>', 
				vim.tbl_extend('force', opts, { desc = "禁用CSV视图" }))
			
			-- 启用CSV视图
			vim.keymap.set('n', '<leader>ce', '<cmd>CsvViewEnable<cr>', 
				vim.tbl_extend('force', opts, { desc = "启用CSV视图" }))
		end,
	})
end

--- 初始化CSV自动配置
function M.setup()
	-- 创建自动命令组
	local csv_auto_group = vim.api.nvim_create_augroup("CsvAutoView", { clear = true })
	
	-- 文件打开时自动检测并启用CSV视图
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		group = csv_auto_group,
		pattern = { "*.csv", "*.tsv", "*.CSV", "*.TSV" },
		callback = function(args)
			M.auto_enable_csv_view(args.buf)
		end,
	})
	
	-- 设置键绑定
	M.setup_csv_keymaps()
	
	-- 创建用户命令
	vim.api.nvim_create_user_command('CsvAutoEnable', function()
		M.auto_enable_csv_view()
	end, { desc = "手动启用CSV自动视图" })
end

return M