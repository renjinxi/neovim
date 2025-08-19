-- Workspaces 配置 - 多项目工作区管理
-- 允许在单个 Neovim 实例中管理多个项目

require("workspaces").setup({
  -- 设置
  hooks = {
    add = {},
    remove = {},
    rename = {},
    open_pre = {
      -- 在打开工作区之前执行的钩子
      "SessionsStop", -- 如果有会话管理器，先停止当前会话
      function()
        -- 清理当前状态
        if vim.bo.filetype == "alpha" then
          vim.cmd("bd")
        end
      end,
    },
    open = {
      -- 打开工作区后执行的钩子
      function()
        -- 刷新 neo-tree 以显示新的根目录
        if pcall(require, "neo-tree") then
          vim.cmd("Neotree filesystem reveal left")
        end
      end,
      "Telescope find_files", -- 打开文件查找器
    },
  },
  
  -- 自动工作区检测模式
  sort = true,
  
  -- 工作区路径标识符（可选，默认使用完整路径）
  path_display = {
    shorten = {
      len = 1,
      exclude = { -1, -2 }  -- 保持最后两个路径段完整
    }
  },
  
  -- 打开工作区时的行为
  auto_dir = true,  -- 自动更改工作目录
  
  -- 全局工作区存储
  global_cd = true,  -- 全局更改目录，而不是仅限于当前窗口
})

-- 多项目工作区管理
local M = {}

-- 当前工作区中的项目列表
M.current_projects = {}

-- 添加项目到当前工作区
function M.add_project_to_workspace(path)
  path = path or vim.fn.getcwd()
  path = vim.fn.fnamemodify(path, ":p:h") -- 规范化路径
  
  -- 检查是否已存在
  for _, existing in ipairs(M.current_projects) do
    if existing == path then
      vim.notify("Project already in workspace: " .. path, vim.log.levels.WARN)
      return
    end
  end
  
  table.insert(M.current_projects, path)
  
  -- 添加到 LSP workspace folders
  if vim.lsp.get_active_clients()[1] then
    vim.lsp.buf.add_workspace_folder(path)
  end
  
  vim.notify("Added project to workspace: " .. path, vim.log.levels.INFO)
end

-- 从工作区移除项目
function M.remove_project_from_workspace(path)
  path = path or vim.fn.getcwd()
  path = vim.fn.fnamemodify(path, ":p:h")
  
  for i, existing in ipairs(M.current_projects) do
    if existing == path then
      table.remove(M.current_projects, i)
      
      -- 从 LSP workspace folders 移除
      if vim.lsp.get_active_clients()[1] then
        vim.lsp.buf.remove_workspace_folder(path)
      end
      
      vim.notify("Removed project from workspace: " .. path, vim.log.levels.INFO)
      return
    end
  end
  
  vim.notify("Project not found in workspace: " .. path, vim.log.levels.WARN)
end

-- 列出当前工作区中的所有项目
function M.list_workspace_projects()
  if #M.current_projects == 0 then
    vim.notify("No projects in current workspace", vim.log.levels.INFO)
    return
  end
  
  vim.ui.select(M.current_projects, {
    prompt = "Projects in workspace:",
  }, function(choice)
    if choice then
      vim.cmd("cd " .. choice)
      -- 如果 nvim-tree 已打开，刷新到新的根目录
      if vim.fn.exists(":NvimTreeOpen") then
        vim.cmd("NvimTreeClose")
        vim.cmd("NvimTreeOpen")
      end
    end
  end)
end

-- 在所有项目中搜索文件
function M.search_all_projects(include_hidden)
  if #M.current_projects == 0 then
    vim.notify("No projects in workspace", vim.log.levels.WARN)
    return
  end
  
  local opts = {
    search_dirs = M.current_projects,
    prompt_title = "Find Files (All Projects)"
  }
  
  -- 控制是否搜索隐藏文件
  if include_hidden then
    opts.hidden = true
    opts.no_ignore = true  -- 忽略 .gitignore
    opts.prompt_title = "Find Files (All Projects, Including Hidden)"
  end
  
  require("telescope.builtin").find_files(opts)
end

-- 在所有项目中搜索文件（包含隐藏文件）
function M.search_all_projects_with_hidden()
  M.search_all_projects(true)
end

-- 在所有项目中搜索文本
function M.grep_all_projects(include_hidden)
  if #M.current_projects == 0 then
    vim.notify("No projects in workspace", vim.log.levels.WARN)
    return
  end
  
  local opts = {
    search_dirs = M.current_projects,
    prompt_title = "Live Grep (All Projects)"
  }
  
  -- 控制是否搜索隐藏文件
  if include_hidden then
    opts.additional_args = function()
      return {"--hidden", "--no-ignore"}
    end
    opts.prompt_title = "Live Grep (All Projects, Including Hidden)"
  end
  
  require("telescope.builtin").live_grep(opts)
end

-- 在所有项目中搜索文本（包含隐藏文件）
function M.grep_all_projects_with_hidden()
  M.grep_all_projects(true)
end

-- 快速切换项目根目录
function M.switch_project_root()
  if #M.current_projects == 0 then
    vim.notify("No projects in workspace", vim.log.levels.WARN)
    return
  end
  
  vim.ui.select(M.current_projects, {
    prompt = "Switch to project:",
    format_item = function(path)
      return vim.fn.fnamemodify(path, ":t") .. " (" .. path .. ")"
    end,
  }, function(choice)
    if choice then
      vim.cmd("cd " .. choice)
      -- 如果 nvim-tree 已打开，刷新到新的根目录
      if vim.fn.exists(":NvimTreeOpen") then
        vim.cmd("NvimTreeClose")
        vim.cmd("NvimTreeOpen")
      end
    end
  end)
end

-- 工作区管理快捷键
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 多项目工作区管理 (使用 <leader>c 前缀)
keymap("n", "<leader>ca", function()
  M.add_project_to_workspace()
end, vim.tbl_extend("force", opts, { desc = "Add project to workspace" }))

keymap("n", "<leader>cA", function()
  vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
    if path then
      M.add_project_to_workspace(vim.fn.expand(path))
    end
  end)
end, vim.tbl_extend("force", opts, { desc = "Add project (specify path)" }))

keymap("n", "<leader>cr", function()
  M.remove_project_from_workspace()
end, vim.tbl_extend("force", opts, { desc = "Remove project from workspace" }))

keymap("n", "<leader>cl", M.list_workspace_projects, vim.tbl_extend("force", opts, { desc = "List workspace projects" }))
keymap("n", "<leader>cs", M.switch_project_root, vim.tbl_extend("force", opts, { desc = "Switch project root" }))

-- 跨项目搜索
keymap("n", "<leader>cf", M.search_all_projects, vim.tbl_extend("force", opts, { desc = "Find files (all projects)" }))
keymap("n", "<leader>cF", M.search_all_projects_with_hidden, vim.tbl_extend("force", opts, { desc = "Find files (all projects + hidden)" }))
keymap("n", "<leader>cg", M.grep_all_projects, vim.tbl_extend("force", opts, { desc = "Grep (all projects)" }))
keymap("n", "<leader>cG", M.grep_all_projects_with_hidden, vim.tbl_extend("force", opts, { desc = "Grep (all projects + hidden)" }))

-- LSP workspace folders 管理
keymap("n", "<leader>caf", vim.lsp.buf.add_workspace_folder, vim.tbl_extend("force", opts, { desc = "Add LSP workspace folder" }))
keymap("n", "<leader>crf", vim.lsp.buf.remove_workspace_folder, vim.tbl_extend("force", opts, { desc = "Remove LSP workspace folder" }))
keymap("n", "<leader>clf", function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, vim.tbl_extend("force", opts, { desc = "List LSP workspace folders" }))

-- Telescope 集成（如果可用）
local function setup_telescope_integration()
  local ok, telescope = pcall(require, "telescope")
  if ok then
    telescope.load_extension("workspaces")
    
    -- 工作区选择的更好界面 (已改为 <leader>c 前缀)
    keymap("n", "<leader>cc", "<cmd>Telescope workspaces<cr>", opts) -- 使用 Telescope 选择工作区
    keymap("n", "<leader>cp", "<cmd>Telescope workspaces<cr>", opts) -- 项目切换的别名
  end
end

-- 延迟设置 Telescope 集成（等待 Telescope 加载）
vim.defer_fn(setup_telescope_integration, 100)

-- 添加多个项目到工作区（兼容旧接口）
function M.add_projects(paths)
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(vim.fn.expand(path)) == 1 then
      M.add_project_to_workspace(vim.fn.expand(path))
    end
  end
end

-- 快速添加开发目录下的所有项目
function M.add_dev_projects(dev_dir)
  dev_dir = dev_dir or "~/dev"
  local expanded_dir = vim.fn.expand(dev_dir)
  
  if vim.fn.isdirectory(expanded_dir) == 0 then
    vim.notify("Directory " .. dev_dir .. " not found", vim.log.levels.WARN)
    return
  end
  
  local handle = vim.loop.fs_scandir(expanded_dir)
  if handle then
    local paths = {}
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if name == nil then break end
      
      if type == "directory" and not name:match("^%.") then
        local full_path = expanded_dir .. "/" .. name
        -- 检查是否是项目目录（有 .git 或 package.json 等）
        if vim.fn.isdirectory(full_path .. "/.git") == 1 or
           vim.fn.filereadable(full_path .. "/package.json") == 1 or
           vim.fn.filereadable(full_path .. "/pyproject.toml") == 1 or
           vim.fn.filereadable(full_path .. "/Cargo.toml") == 1 or
           vim.fn.filereadable(full_path .. "/go.mod") == 1 then
          table.insert(paths, full_path)
        end
      end
    end
    
    -- 添加所有找到的项目到当前工作区
    for _, path in ipairs(paths) do
      M.add_project_to_workspace(path)
    end
    vim.notify("Added " .. #paths .. " projects from " .. dev_dir, vim.log.levels.INFO)
  end
end

-- 用户命令
vim.api.nvim_create_user_command("WorkspacesAddDev", function(opts)
  M.add_dev_projects(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = "dir",
  desc = "Add all projects from development directory",
})

return M