local common = require('user.config.common')

local function custom_python_path(file_path)
    local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.fn.getcwd()
    local python_interpreter = project_root .. "/.venv/bin/python" -- Adjust this based on your env path
    return python_interpreter
end

local function get_python_env(file_path)
    local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.fn.getcwd()
    return {
        PYTHONPATH = project_root,
        --PYTHONPATH = "/home/username/your_project",
        --PYTHONPATH = "/home/username/your_project/your_module",

    }
end

require("neotest").setup({
    adapters = {
        require("neotest-python")({
            dap = { justMyCode = false },
            runner = "pytest",
            python = custom_python_path,
            command = "coverage run -m pytest"
            --env = get_python_env,

        }),
        --require("neotest-plenary"),
        --require("neotest-vim-test")({
        --ignore_file_types = { "python", "vim", "lua" },
        --}),
    },
    --discovery = {
    --root_dir = function(startpath)
    --return require('neotest.lib').files.find_upwards(function(dir)
    --return require('neotest.lib').files.exists(dir .. "/pyproject.toml") or
    --require('neotest.lib').files.exists(dir .. "/.git")
    --end, startpath) or startpath
    --end,
    --},
})
