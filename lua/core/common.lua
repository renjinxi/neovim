M = {}

M.find_project_root_by_marker = function(marker)
	--local path = start_path
	--local path = vim.fn.getcwd()
	local current_buf = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(current_buf)
	--return buf_name
	while path ~= nil and path ~= "/" do
		local marker_path = vim.fn.glob(path .. "/" .. marker)
		if marker_path ~= "" then
			return path
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
	return nil -- Falling back to the current working directory or another default
end

return M
