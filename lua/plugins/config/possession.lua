-- Possession 配置 - 专门为多项目工作区设计的会话管理器
-- 比 sessions.nvim 更适合多项目工作流

require("possession").setup({
  -- 会话保存目录
  session_dir = vim.fn.stdpath("data") .. "/possession",
  
  -- 自动保存设置
  silent = false,
  load_silent = true,
  debug = false,
  logfile = false,
  
  -- 会话命名策略
  prompt_no_cr = false,
  autosave = {
    current = false,  -- 不自动保存当前会话
    tmp = false,      -- 不保存临时会话
    tmp_name = "tmp", -- 临时会话名称
    on_load = true,   -- 加载时自动保存
    on_quit = true,   -- 退出时自动保存
  },
  
  -- 会话内容配置
  commands = {
    save = "PossessionSave",
    load = "PossessionLoad",
    rename = "PossessionRename",
    close = "PossessionClose",
    delete = "PossessionDelete",
    show = "PossessionShow",
    list = "PossessionList",
    migrate = "PossessionMigrate",
  },
  
  -- 钩子配置
  hooks = {
    before_save = function(name)
      -- 保存会话前的清理工作
      -- 关闭所有浮动窗口
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
          pcall(vim.api.nvim_win_close, win, false)
        end
      end
      
      -- 保存工作区项目列表到会话数据
      local workspaces_config = require("plugins.config.workspaces")
      return {
        workspace_projects = vim.deepcopy(workspaces_config.get_current_projects())
      }
    end,
    after_save = function(name, user_data, aborted)
      if not aborted then
        vim.notify("Session saved: " .. name, vim.log.levels.INFO)
      end
    end,
    before_load = function(name, user_data)
      -- 加载前清理当前状态
      if vim.bo.filetype == "dashboard" or vim.bo.filetype == "alpha" then
        vim.cmd("bd")
      end
      return user_data
    end,
    after_load = function(name, user_data, aborted)
      if not aborted then
        vim.notify("Session loaded: " .. name, vim.log.levels.INFO)
        
        -- 恢复工作区项目列表和刷新文件树
        vim.defer_fn(function()
          local workspaces_config = require("plugins.config.workspaces")
          
          -- 从会话数据中恢复项目列表
          if user_data and user_data.workspace_projects then
            workspaces_config.set_current_projects(user_data.workspace_projects)
            vim.notify("Restored " .. #user_data.workspace_projects .. " projects to workspace", vim.log.levels.INFO)
          end
          
          -- 刷新文件树
          if vim.fn.exists(":NvimTreeOpen") then
            vim.cmd("NvimTreeClose")
            vim.cmd("NvimTreeOpen")
          end
        end, 200)
      end
    end,
  },
  
  -- 自动检测项目会话配置
  plugins = {
    close_windows = {
      hooks = {"before_save", "before_load"},
      preserve_layout = true, -- 保持窗口布局
      match = {
        floating = true,
        buftype = {
          "",
          "acwrite",
          "help",
          "nofile",
          "nowrite",
          "quickfix",
          "terminal",
          "prompt",
        },
        filetype = {},
        custom = false, -- 自定义匹配函数
      },
    },
    
    delete_hidden_buffers = {
      hooks = {
        "before_load",
        vim.o.sessionoptions:match("buffer") and "before_save",
      },
      force = false, -- 强制删除修改过的缓冲区
    },
    
    nvim_tree = true,       -- 自动保存/恢复 nvim-tree 状态
    neo_tree = true,        -- 自动保存/恢复 neo-tree 状态
    symbols_outline = true, -- 保存 symbols-outline 状态
    tabby = true,           -- 保存标签页状态
    dap = true,             -- 保存调试器状态
    dapui = true,           -- 保存调试器 UI 状态
    neotest = true,         -- 保存测试状态
    delete_buffers = false, -- 不自动删除缓冲区
  },
})

-- 工作区会话管理功能
local M = {}

-- 获取当前工作区的会话名称
function M.get_workspace_session_name()
  local cwd = vim.fn.getcwd()
  -- 使用目录名作为会话名，更友好
  return vim.fn.fnamemodify(cwd, ":t") or "default"
end

-- 获取基于路径的会话名称（用于唯一性）
function M.get_workspace_session_path()
  local cwd = vim.fn.getcwd()
  return cwd:gsub("/", "_"):gsub("^_", ""):gsub("%.", "_")
end

-- 为当前工作区保存会话
function M.save_workspace_session()
  local session_name = M.get_workspace_session_name()
  local session_path = M.get_workspace_session_path()
  
  -- 如果会话名冲突，使用完整路径
  local possession = require("possession")
  local existing_sessions = possession.list()
  
  for _, existing in ipairs(existing_sessions) do
    if existing.name == session_name and existing.cwd ~= vim.fn.getcwd() then
      session_name = session_path
      break
    end
  end
  
  vim.cmd("PossessionSave " .. session_name)
end

-- 加载工作区会话
function M.load_workspace_session()
  local session_name = M.get_workspace_session_name()
  local possession = require("possession")
  local sessions = possession.list()
  
  -- 查找匹配当前工作目录的会话
  for _, session in ipairs(sessions) do
    if (session.name == session_name and session.cwd == vim.fn.getcwd()) or
       session.name == M.get_workspace_session_path() then
      vim.cmd("PossessionLoad " .. session.name)
      return
    end
  end
  
  vim.notify("No session found for current workspace: " .. session_name, vim.log.levels.WARN)
end

-- 删除工作区会话
function M.delete_workspace_session()
  local session_name = M.get_workspace_session_name()
  local possession = require("possession")
  local sessions = possession.list()
  
  for _, session in ipairs(sessions) do
    if (session.name == session_name and session.cwd == vim.fn.getcwd()) or
       session.name == M.get_workspace_session_path() then
      vim.cmd("PossessionDelete " .. session.name)
      return
    end
  end
  
  vim.notify("No session found to delete for workspace: " .. session_name, vim.log.levels.WARN)
end

-- 列出所有工作区会话
function M.list_workspace_sessions()
  local possession = require("possession")
  local sessions = possession.list()
  
  if #sessions == 0 then
    vim.notify("No sessions found", vim.log.levels.INFO)
    return
  end
  
  -- 使用内置的 PossessionList 命令，它有更好的界面
  vim.cmd("PossessionList")
end

-- Telescope 集成
function M.setup_telescope_integration()
  local ok, telescope = pcall(require, "telescope")
  if ok then
    -- 注册 possession telescope 扩展
    pcall(telescope.load_extension, "possession")
  end
end

-- 快捷键已迁移到 /lua/plugins/keymaps/project/sessions.lua

-- 增强命令
vim.api.nvim_create_user_command("SessionSaveWorkspace", M.save_workspace_session, {
  desc = "Save session for current workspace",
})

vim.api.nvim_create_user_command("SessionLoadWorkspace", M.load_workspace_session, {
  desc = "Load session for current workspace",
})

vim.api.nvim_create_user_command("SessionDeleteWorkspace", M.delete_workspace_session, {
  desc = "Delete session for current workspace",
})

-- 延迟设置 Telescope 集成
vim.defer_fn(M.setup_telescope_integration, 100)

-- 自动工作区会话管理（可选）
function M.setup_auto_workspace_session()
  local workspace_session_group = vim.api.nvim_create_augroup("WorkspaceSession", { clear = true })
  
  -- 在切换目录时自动加载对应的会话
  vim.api.nvim_create_autocmd("DirChanged", {
    group = workspace_session_group,
    pattern = "global",
    callback = function()
      vim.defer_fn(function()
        -- 只在项目目录中自动加载会话
        if vim.fn.isdirectory(".git") == 1 or
           vim.fn.filereadable("package.json") == 1 or
           vim.fn.filereadable("pyproject.toml") == 1 or
           vim.fn.filereadable("Cargo.toml") == 1 then
          M.load_workspace_session()
        end
      end, 500)
    end,
  })
  
  -- 退出时自动保存工作区会话
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = workspace_session_group,
    callback = function()
      -- 如果在项目目录中，自动保存会话
      if vim.fn.isdirectory(".git") == 1 or
         vim.fn.filereadable("package.json") == 1 or
         vim.fn.filereadable("pyproject.toml") == 1 then
        M.save_workspace_session()
      end
    end,
  })
end

-- 可选：启用自动工作区会话管理
-- 取消注释下面的行来启用
-- M.setup_auto_workspace_session()

return M