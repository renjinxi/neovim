local settings = {}

local state, local_settings = pcall(require, "user.local_settings")

if state then
        for k, v in pairs(local_settings) do
                local_settings[k] = v
        end
end

return settings
