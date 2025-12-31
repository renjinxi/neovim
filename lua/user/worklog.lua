-- 个人工作日志系统
-- 用于记录「卡住」「不爽」「灵感」三类事件
local M = {}

local log_dir = vim.fn.expand('~/.local/share/worklog')
local float_win = nil
local float_buf = nil

local function ensure_dir()
  if vim.fn.isdirectory(log_dir) == 0 then
    vim.fn.mkdir(log_dir, 'p')
  end
end

local function get_week_file()
  return log_dir .. '/' .. os.date('%Y-W%W') .. '.md'
end

local function close_float()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, true)
  end
  float_win = nil
  float_buf = nil
end

local function open_log()
  ensure_dir()
  local file = get_week_file()
  -- 如果文件不存在，创建时加入周标题
  if vim.fn.filereadable(file) == 0 then
    local header = '# Week ' .. os.date('%Y-W%W')
    vim.fn.writefile({ header }, file)
  end

  -- 如果浮动窗口已存在，直接聚焦
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_set_current_win(float_win)
    vim.cmd('normal! G')
    return
  end

  -- 创建浮动窗口
  local width = 50
  local height = 12

  float_buf = vim.fn.bufnr(file, true)
  vim.fn.bufload(float_buf)

  float_win = vim.api.nvim_open_win(float_buf, true, {
    relative = 'cursor',
    width = width,
    height = height,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded',
    title = ' Journal ',
    title_pos = 'center',
  })

  -- 设置浮动窗口选项
  vim.wo[float_win].wrap = true
  vim.wo[float_win].linebreak = true

  -- q 关闭浮动窗口
  vim.keymap.set('n', 'q', close_float, { buffer = float_buf, nowait = true })

  vim.cmd('normal! G')
end

-- 生成唯一 ID: 类型首字母 + 短 UUID (如 F-a1b2c3d4)
local function generate_id(type)
  local prefix = type:sub(1, 1):upper() -- F/S/I
  -- 使用 uuidgen 生成 UUID，取前 8 位
  local handle = io.popen('uuidgen | cut -c1-8 | tr A-Z a-z')
  local uuid = handle:read('*a'):gsub('%s+', '')
  handle:close()
  return prefix .. '-' .. uuid
end

local function insert_template(type)
  local id = generate_id(type)
  local entry = os.date('\n%Y-%m-%d %H:%M') .. ' ' .. type .. ' [' .. id .. ']\n'
  local lines = vim.split(entry, '\n')
  vim.api.nvim_put(lines, 'l', true, true)
  vim.cmd('startinsert!')
end

function M.setup()
  local keymap = vim.keymap.set

  -- 打开本周日志
  keymap('n', '<leader>jl', function()
    open_log()
  end, { desc = 'Journal: open' })

  -- 快速记录：卡住
  keymap('n', '<leader>js', function()
    open_log()
    insert_template('stuck')
  end, { desc = 'Journal: stuck' })

  -- 快速记录：不爽
  keymap('n', '<leader>jf', function()
    open_log()
    insert_template('friction')
  end, { desc = 'Journal: friction' })

  -- 快速记录：灵感
  keymap('n', '<leader>ja', function()
    open_log()
    insert_template('idea')
  end, { desc = 'Journal: idea (aha)' })

  -- 临时草稿浮动框（不保存）
  keymap('n', '<leader>jt', function()
    local width = 60
    local height = 15
    local buf = vim.api.nvim_create_buf(false, true) -- nofile, scratch
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'markdown'
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      style = 'minimal',
      border = 'rounded',
      title = ' Scratch ',
      title_pos = 'center',
    })
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
    vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
    vim.cmd('startinsert')
  end, { desc = 'Journal: scratch (temp)' })
end

return M
