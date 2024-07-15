local settings = {
	debug_python_path = "/usr/local/bin/python3",
}

local state, local_settings = pcall(require, "config.local_settings")

if state then
	for k, v in pairs(local_settings) do
		settings[k] = v
	end
end

return settings
