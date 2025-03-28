local M = {}

-- 读取 .env 文件的函数
local function load_env_file(file_path)
    local env_vars = {}
    local file = io.open(file_path, "r")
    
    if file then
        for line in file:lines() do
            -- 跳过注释和空行
            if not line:match("^%s*#") and line:match("%S") then
                local key, value = line:match("^%s*(.-)%s*=%s*\"?([^\"]*)\"?%s*$")
                if key and value then
                    env_vars[key] = value
                end
            end
        end
        file:close()
    end
    return env_vars
end

-- 获取配置目录路径
local config_path = vim.fn.stdpath("config")
local env_path = config_path .. "/.env"
local env_example_path = config_path .. "/.env.example"

-- 尝试加载 .env 文件，如果不存在则加载 .env.example
local env_vars = load_env_file(env_path) or load_env_file(env_example_path) or {}

-- 导出环境变量获取函数
function M.get(key, default)
    return env_vars[key] or default
end

-- 导出所有环境变量
function M.get_all()
    return vim.deepcopy(env_vars)
end

return M 