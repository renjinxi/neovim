local M = {}

function M.get_env(extra_env)
	local env = vim.fn.environ()
	-- fnm default node + nvm node + local bin
	local fnm_default = vim.fn.expand("$HOME/.local/share/fnm/aliases/default/bin")
	local nvm_node = vim.fn.expand("$HOME/.nvm/versions/node/v22.12.0/bin")
	local local_bin = vim.fn.expand("$HOME/.local/bin")
	env.PATH = local_bin .. ":" .. fnm_default .. ":" .. nvm_node .. ":" .. (env.PATH or "")
	for k, v in pairs(extra_env or {}) do
		env[k] = v
	end
	return env
end

function M.normalize_spec(spec_or_cmd)
	if type(spec_or_cmd) == "table" then
		return vim.tbl_deep_extend("force", {}, spec_or_cmd)
	end
	return { cmd = spec_or_cmd }
end

function M.termopen(spec_or_cmd, opts)
	local spec = M.normalize_spec(spec_or_cmd)
	return vim.fn.termopen(spec.cmd, vim.tbl_extend("force", {
		env = M.get_env(spec.env),
		cwd = spec.cwd and vim.fn.expand(spec.cwd) or nil,
	}, opts or {}))
end

function M.termopen_shell(spec_or_cmd, opts)
	local spec = M.normalize_spec(spec_or_cmd)
	return vim.fn.termopen({ "zsh", "-ic", spec.cmd }, vim.tbl_extend("force", {
		env = M.get_env(spec.env),
		cwd = spec.cwd and vim.fn.expand(spec.cwd) or nil,
	}, opts or {}))
end

return M
