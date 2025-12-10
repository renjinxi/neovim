return {
	name = "Android: Clean",
	builder = function()
		local cwd = vim.fn.getcwd()
		return {
			cmd = { "./gradlew", "clean" },
			cwd = cwd,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		}
	end,
	condition = {
		callback = function()
			-- 检查当前目录是否有 gradlew 文件
			return vim.fn.filereadable("gradlew") == 1 or vim.fn.filereadable("build.gradle") == 1
		end,
	},
}
