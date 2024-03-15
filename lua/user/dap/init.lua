local status_ok, dap = pcall(require, "dap")
if not status_ok then
    return
end

--local status_ok, dap_ui = pcall(require, "dapui")
--if status_ok then
--dap_ui.setup()
--end

local settings = require("user.settings")
local python_path = settings.debug_python_path
dap.adapters.python = {
    type = "executable",
    command = python_path,
    args = { "-m", "debugpy.adapter" },
}

require("dap-python").setup(python_path)
require("dap.ext.vscode").load_launchjs(".nvim/launch.json", nil)


table.insert(dap.configurations.python, {
    type = "python",
    request = "launch",
    name = "My Launch file with args",
    program = "${file}",
    justMyCode = false,
    args = function()
        local args_string = vim.fn.input("Arguments: ")
        return vim.split(args_string, " +")
    end,
    console = "integratedTerminal",
    pythonPath = function()
        local path = vim.fn.input("Python Path: ")
        --return python_path
        return path
    end,
})

table.insert(dap.configurations.python, {
    type = "python",
    request = "launch",
    name = "My Django",
    program = "${file}",
    justMyCode = false,
    django = true,
    args = function()
        local args_string = vim.fn.input("Arguments: ")
        return vim.split(args_string, " +")
    end,
    console = "integratedTerminal",
    pythonPath = function()
        local path = vim.fn.input("Python Path: ")
        --return python_path
        return path
    end,
})

dap.adapters.lldb = {
    type = "executable",
    command = "/usr/local/Cellar/llvm/17.0.2/bin/lldb-vscode", -- adjust as needed, must be absolute path
    name = "lldb",
}

dap.configurations.c = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " +")
        end,

        -- 💀
        -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
        --
        --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
        --
        -- Otherwise you might get the following error:
        --
        --    Error on launch: Failed to attach to the target process
        --
        -- But you should be aware of the implications:
        -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
        -- runInTerminal = false,
    },
}
require("user.dap.keymap")
require("nvim-dap-virtual-text").setup()
require("telescope").load_extension("dap")
