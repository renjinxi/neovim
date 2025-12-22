-- 个人工作日志系统
-- 用于记录「卡住」「不爽」「灵感」三类事件
local M = {}

local log_dir = vim.fn.expand('~/.local/share/worklog')

local function ensure_dir()
  if vim.fn.isdirectory(log_dir) == 0 then
    vim.fn.mkdir(log_dir, 'p')
  end
end

local function get_week_file()
  return log_dir .. '/' .. os.date('%Y-W%W') .. '.md'
end

local function open_log()
  ensure_dir()
  local file = get_week_file()
  -- 如果文件不存在，创建时加入周标题
  if vim.fn.filereadable(file) == 0 then
    local header = '# Week ' .. os.date('%Y-W%W') .. '\n'
    vim.fn.writefile({ header }, file)
  end
  vim.cmd('edit ' .. file)
  vim.cmd('normal! G')
end

local function insert_template(type)
  local templates = {
    stuck = '### 卡住\n- 在哪：\n- 试了：\n- 通了：',
    friction = '### 不爽\n- 场景：\n- 感受：',
    idea = '### 灵感\n- 想法：',
  }
  local timestamp = os.date('\n## %m-%d %H:%M\n')
  local lines = vim.split(timestamp .. templates[type], '\n')
  vim.api.nvim_put(lines, 'l', true, true)
  -- 定位到第一个需要填写的位置
  vim.cmd('normal! 2k$')
end

function M.setup()
  local keymap = vim.keymap.set

  -- 打开本周日志
  keymap('n', '<leader>wl', function()
    open_log()
  end, { desc = 'Worklog: open' })

  -- 快速记录：卡住
  keymap('n', '<leader>ws', function()
    open_log()
    insert_template('stuck')
  end, { desc = 'Worklog: stuck' })

  -- 快速记录：不爽
  keymap('n', '<leader>wf', function()
    open_log()
    insert_template('friction')
  end, { desc = 'Worklog: friction' })

  -- 快速记录：灵感
  keymap('n', '<leader>wi', function()
    open_log()
    insert_template('idea')
  end, { desc = 'Worklog: idea' })
end

return M
