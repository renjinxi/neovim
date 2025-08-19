local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

-- Helper functions (from original lualine config)
local function window()
	return vim.api.nvim_win_get_number(0)
end

local function cond200()
	return vim.fn.winwidth(0) > 200
end

local function cond80()
	return vim.fn.winwidth(0) > 80
end

local function cond40()
	return vim.fn.winwidth(0) > 40
end

local function clock()
	return os.date("%Y-%m-%d %H:%M")
end

local function get_project_root()
	local cwd = vim.loop.cwd()
	while true do
		if vim.loop.fs_stat(cwd .. "/.git") then
			return cwd:match("([^/\\]+)$")
		end
		local parent = cwd:match("(.*)[/\\]")
		if not parent or parent == cwd then
			break
		end
		cwd = parent
	end
	return "[No Project]"
end

-- Rose Pine Dark color palette (official)
local colors = {
	-- Rose Pine Dark base colors
	base = "#191724",        -- main background (dark)
	surface = "#1f1d2e",     -- slightly lighter background
	overlay = "#26233a",     -- overlay background
	muted = "#6e6a86",       -- muted text
	subtle = "#908caa",      -- subtle text
	text = "#e0def4",        -- main text
	
	-- Rose Pine Dark accent colors
	love = "#eb6f92",        -- pink/red
	gold = "#f6c177",        -- yellow
	rose = "#ebbcba",        -- rose
	pine = "#31748f",        -- teal
	foam = "#9ccfd8",        -- cyan
	iris = "#c4a7e7",        -- purple
	leaf = "#56949f",        -- leaf green
	
	-- Rose Pine Dark backgrounds for statusline
	light_bg = "#191724",    -- main statusline background
	bright_bg = "#26233a",   -- grouped sections background
	clock_bg = "#403d52",    -- clock background
	subtle_bg = "#1f1d2e",   -- subtle sections
	
	-- Tab colors using lighter Rose Pine colors
	tab_active_bg = "#f2e9e1",   -- Rose Pine Dawn base - light
	tab_inactive_bg = "#f2e9e1", -- Rose Pine Dawn base - light
	tab_border_bg = "#f2e9e1",   -- Rose Pine Dawn base - light (entire tabline bg)
	
	-- Text colors for light background
	tab_active_text = "#575279",   -- Rose Pine Dawn text - dark on light
	tab_inactive_text = "#797593", -- Rose Pine Dawn subtle - muted on light
	statusline_text = "#e0def4",   -- statusline text
	
	-- Mode-specific backgrounds using Rose Pine Dark colors
	mode_bg = {
		n = "#eb6f92",       -- normal (love)
		i = "#31748f",       -- insert (pine)
		v = "#c4a7e7",       -- visual (iris)
		c = "#f6c177",       -- command (gold)
		s = "#9ccfd8",       -- select (foam)
		r = "#ebbcba",       -- replace (rose)
		t = "#eb6f92",       -- terminal (love)
	},
	
	-- Text colors for Rose Pine Dark theme
	mode_fg = "#191724",     -- base dark for mode backgrounds
	bright_fg = "#e0def4",   -- main text color
	statusline_text = "#e0def4", -- main text for statusline
	gray = "#6e6a86",        -- muted color
	
	-- Diagnostic colors using Rose Pine Dark palette
	diag_error = "#eb6f92",  -- love
	diag_warn = "#f6c177",   -- gold
	diag_info = "#31748f",   -- pine
	diag_hint = "#9ccfd8",   -- foam
	
	-- Git colors using Rose Pine Dark palette
	git_add = "#31748f",     -- pine
	git_del = "#eb6f92",     -- love
	git_change = "#f6c177",  -- gold
}

-- Window number and Mode component
local ViModeBase = {
	init = function(self)
		self.mode = vim.fn.mode(1)
	end,
	static = {
		mode_names = {
			n = "NORMAL",
			no = "N-OP",
			nov = "N-OP",
			noV = "N-OP",
			["no\22"] = "N-OP",
			niI = "N-INSERT",
			niR = "N-REPLACE",
			niV = "N-V",
			nt = "TERMINAL",
			v = "VISUAL",
			vs = "V-SELECT",
			V = "V-LINE",
			Vs = "V-SELECT",
			["\22"] = "V-BLOCK",
			["\22s"] = "V-BLOCK",
			s = "SELECT",
			S = "S-LINE",
			["\19"] = "S-BLOCK",
			i = "INSERT",
			ic = "INSERT",
			ix = "INSERT",
			R = "REPLACE",
			Rc = "REPLACE",
			Rx = "REPLACE",
			Rv = "V-REPLACE",
			Rvc = "V-REPLACE",
			Rvx = "V-REPLACE",
			c = "COMMAND",
			cv = "EX",
			r = "PROMPT",
			rm = "MORE",
			["r?"] = "CONFIRM",
			["!"] = "SHELL",
			t = "TERMINAL",
		}
	},
	provider = function(self)
		return " " .. window() .. " " .. self.mode_names[self.mode] .. " "
	end,
	hl = function(self)
		return { fg = colors.mode_fg, bold = true }
	end,
	update = {
		"ModeChanged",
		pattern = "*:*",
		callback = vim.schedule_wrap(function()
			vim.cmd("redrawstatus")
		end),
	},
}

-- Surround ViMode with Dawn colored background
local ViMode = utils.surround({ "", "" }, function(self)
	local mode = vim.fn.mode(1):sub(1, 1)
	return colors.mode_bg[mode] or colors.mode_bg.n
end, ViModeBase)

-- Git info (lualine_b)
local Git = {
	condition = conditions.is_git_repo,

	init = function(self)
		self.status_dict = vim.b.gitsigns_status_dict
		self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
	end,

	hl = { fg = colors.rose },

	{
		provider = function(self)
			return "  " .. self.status_dict.head
		end,
		hl = { bold = true }
	},
	{
		condition = function(self)
			return self.has_changes
		end,
		provider = "(",
	},
	{
		provider = function(self)
			local count = self.status_dict.added or 0
			return count > 0 and ("+" .. count)
		end,
		hl = { fg = colors.pine },
	},
	{
		provider = function(self)
			local count = self.status_dict.removed or 0
			return count > 0 and ("-" .. count)
		end,
		hl = { fg = colors.love },
	},
	{
		provider = function(self)
			local count = self.status_dict.changed or 0
			return count > 0 and ("~" .. count)
		end,
		hl = { fg = colors.gold },
	},
	{
		condition = function(self)
			return self.has_changes
		end,
		provider = ")",
	},
}

-- Diagnostics
local Diagnostics = {
	condition = conditions.has_diagnostics,

	static = {
		error_icon = " ",
		warn_icon = " ", 
		info_icon = " ",
		hint_icon = "󰌵 ",
	},

	init = function(self)
		self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
		self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	end,

	update = { "DiagnosticChanged", "BufEnter" },

	{
		provider = function(self)
			return self.errors > 0 and (self.error_icon .. self.errors .. " ")
		end,
		hl = { fg = colors.love },
	},
	{
		provider = function(self)
			return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
		end,
		hl = { fg = colors.gold },
	},
	{
		provider = function(self)
			return self.info > 0 and (self.info_icon .. self.info .. " ")
		end,
		hl = { fg = colors.pine },
	},
	{
		provider = function(self)
			return self.hints > 0 and (self.hint_icon .. self.hints)
		end,
		hl = { fg = colors.foam },
	},
}

-- Filename (lualine_c)
local FileNameBlock = {
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
}

local FileName = {
	provider = function(self)
		local filename = vim.fn.fnamemodify(self.filename, ":.")
		if filename == "" then return "[No Name]" end
		return filename
	end,
	hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
	{
		condition = function()
			return vim.bo.modified
		end,
		provider = "[+]",
		hl = { fg = colors.green },
	},
	{
		condition = function()
			return not vim.bo.modifiable or vim.bo.readonly
		end,
		provider = "",
		hl = { fg = colors.orange },
	},
}

FileNameBlock = utils.insert(FileNameBlock, FileName, FileFlags, { provider = '%<'})

-- File info (lualine_x)
local FileType = {
	provider = function()
		local ft = vim.bo.filetype
		if ft == "" then return "" end
		return " " .. string.upper(ft)
	end,
	hl = { fg = colors.iris, bold = true },
}

local FileEncoding = {
	provider = function()
		local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
		return enc ~= 'utf-8' and enc:upper()
	end
}

local FileFormat = {
	provider = function()
		local fmt = vim.bo.fileformat
		return fmt ~= 'unix' and fmt:upper()
	end
}

-- Copilot status
local Copilot = {
	condition = function()
		return package.loaded["copilot"] ~= nil
	end,
	provider = function()
		local copilot_on = vim.fn["copilot#Enabled"]() == 1
		return copilot_on and "  " or ""
	end,
	hl = { fg = colors.pine },
}

-- Ruler (lualine_y)
local Ruler = {
	provider = "%7(%l/%3L%):%2c %P",
}

-- Clock (lualine_z) 
local Clock = {
	provider = function()
		return clock()
	end,
	hl = { fg = colors.text, bold = true },
}

-- Separators
local LeftSep = { provider = " ", hl = { fg = colors.gray } }
local RightSep = { provider = " ", hl = { fg = colors.gray } }

-- Align component
local Align = { provider = "%=" }
local Space = { provider = " " }

-- StatusLine with deep theme
local StatusLine = {
	hl = { bg = colors.light_bg, fg = colors.statusline_text },  -- deep gray background
	
	-- Mode section with colorful background
	ViMode, 
	{ provider = " ", hl = { bg = colors.light_bg } },
	
	-- Git and diagnostics with grouped background
	utils.surround({ "", "" }, colors.bright_bg, { 
		{ provider = " " },
		Git, 
		{ provider = " " },
		Diagnostics,
		{ provider = " " }
	}),
	{ provider = " ", hl = { bg = colors.light_bg } },
	
	-- Filename in main background
	{ FileNameBlock, hl = { bg = colors.light_bg, fg = colors.statusline_text } },
	
	-- Spacer
	Align,
	
	-- File info with grouped background
	utils.surround({ "", "" }, colors.bright_bg, {
		{ provider = " " },
		Copilot,
		{ provider = " " },
		FileEncoding,
		{ provider = " " },
		FileFormat, 
		{ provider = " " },
		FileType,
		{ provider = " " }
	}),
	{ provider = " ", hl = { bg = colors.light_bg } },
	
	-- Clock with highlight background 
	utils.surround({ "", "" }, colors.clock_bg, {
		{ provider = " " },
		Clock,
		{ provider = " " }
	}),
}

-- TabLine 
local TablineBufnr = {
	provider = function(self)
		return tostring(self.bufnr) .. ". "
	end,
	hl = "Comment",
}

local TablineFileName = {
	provider = function(self)
		local filename = self.filename
		filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":t")
		return filename
	end,
	hl = function(self)
		if self.is_active then
			return { fg = colors.tab_active_text, bold = true }  -- active tab with bold dark brown
		else
			return { fg = colors.tab_inactive_text }  -- inactive tab with lighter brown
		end
	end,
}

local TablineFileFlags = {
	{
		condition = function(self)
			return vim.api.nvim_buf_get_option(self.bufnr, "modified")
		end,
		provider = "[+]",
		hl = { fg = colors.green },
	},
	{
		condition = function(self)
			return not vim.api.nvim_buf_get_option(self.bufnr, "modifiable")
			or vim.api.nvim_buf_get_option(self.bufnr, "readonly")
		end,
		provider = function(self)
			if vim.api.nvim_buf_get_option(self.bufnr, "buftype") == "terminal" then
				return "  "
			else
				return ""
			end
		end,
		hl = { fg = colors.orange },
	},
}

local TablineFileNameBlock = {
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(self.bufnr)
	end,
	hl = function(self)
		if self.is_active then
			return "TabLineSel"
		else
			return "TabLine"
		end
	end,
	on_click = {
		callback = function(_, minwid, _, _)
			vim.api.nvim_win_set_buf(0, minwid)
		end,
		minwid = function(self)
			return self.bufnr
		end,
		name = "heirline_tabline_buffer_callback",
	},
	TablineBufnr,
	TablineFileName,
	TablineFileFlags,
}

local TablineCloseButton = {
	condition = function(self)
		return not vim.api.nvim_buf_get_option(self.bufnr, "modified")
	end,
	{ provider = " " },
	{
		provider = "",
		hl = { fg = colors.gray },
		on_click = {
			callback = function(_, minwid, _, _)
				vim.schedule(function()
					vim.api.nvim_buf_delete(minwid, { force = false })
					vim.cmd.redrawtabline()
				end)
			end,
			minwid = function(self)
				return self.bufnr
			end,
			name = "heirline_tabline_close_buffer_callback",
		},
	},
}

local TablinePicker = {
	condition = function(self)
		return self._show_picker
	end,
	init = function(self)
		local bufname = vim.api.nvim_buf_get_name(self.bufnr)
		bufname = vim.fn.fnamemodify(bufname, ":t")
		local label = bufname:sub(1, 1)
		local i = 2
		while self._picker_labels[label] do
			if i > #bufname then
				break
			end
			label = bufname:sub(i, i)
			i = i + 1
		end
		self._picker_labels[label] = self.bufnr
		self.label = label
	end,
	provider = function(self)
		return self.label
	end,
	hl = { fg = colors.red, bold = true },
}

vim.keymap.set("n", "gbp", function()
	local tabline = require("heirline").tabline
	local buflist = tabline._buflist[1]
	buflist._picker_labels = {}
	buflist._show_picker = true
	vim.cmd.redrawtabline()
	local char = vim.fn.getcharstr()
	local bufnr = buflist._picker_labels[char]
	if bufnr then
		vim.api.nvim_win_set_buf(0, bufnr)
	end
	buflist._show_picker = false
	vim.cmd.redrawtabline()
end)

local TablineBufferBlock = utils.surround({ "", "" }, function(self)
	if self.is_active then
		return colors.tab_active_bg  -- soft rose-gray for active tab
	else
		return colors.tab_inactive_bg  -- lighter rose tint for inactive tab
	end
end, {
	-- 添加条件过滤：只显示当前标签页中可见的buffer
	condition = function(self)
		local current_tabpage = vim.api.nvim_get_current_tabpage()
		local windows = vim.api.nvim_tabpage_list_wins(current_tabpage)
		
		-- 检查这个buffer是否在当前标签页的某个窗口中显示
		for _, win in ipairs(windows) do
			if vim.api.nvim_win_get_buf(win) == self.bufnr then
				-- 同时检查buffer类型
				local buftype = vim.api.nvim_buf_get_option(self.bufnr, "buftype")
				return buftype == "" or buftype == "acwrite"
			end
		end
		return false
	end,
	
	TablinePicker,
	TablineFileNameBlock,
	TablineCloseButton,
})

-- 简单回退到原来的实现，但添加条件过滤
local BufferLine = utils.make_buflist(
	TablineBufferBlock,
	{ provider = "", hl = { fg = colors.tab_border_bg } },  -- subtle border separators
	{ provider = "", hl = { fg = colors.tab_border_bg } }
)

local Tabpage = {
	provider = function(self)
		return "%" .. self.tabnr .. "T " .. self.tabnr .. " %T"
	end,
	hl = function(self)
		if not self.is_active then
			return "TabLine"
		else
			return "TabLineSel"
		end
	end,
}

local TabPages = {
	condition = function()
		return #vim.api.nvim_list_tabpages() >= 2
	end,
	{ provider = "%=" },
	utils.make_tablist(Tabpage),
}

local TabLineOffset = {
	condition = function(self)
		local win = vim.api.nvim_tabpage_list_wins(0)[1]
		local bufnr = vim.api.nvim_win_get_buf(win)
		self.winid = win

		if vim.bo[bufnr].filetype == "NvimTree" then
			self.title = "NvimTree"
			return true
		end
	end,

	provider = function(self)
		local title = self.title
		local width = vim.api.nvim_win_get_width(self.winid)
		local pad = math.ceil((width - #title) / 2)
		return string.rep(" ", pad) .. title .. string.rep(" ", pad)
	end,

	hl = function(self)
		if vim.api.nvim_get_current_win() == self.winid then
			return "TablineSel"
		else
			return "Tabline"
		end
	end,
}

local TabLine = { 
	hl = { bg = colors.tab_border_bg, fg = colors.tab_active_text },  -- black background for entire tabline
	TabLineOffset, BufferLine, TabPages,
	-- Fill remaining space with black background
	{ provider = "%=", hl = { bg = colors.tab_border_bg } }
}

-- Setup
require("heirline").setup({
	statusline = StatusLine,
	tabline = TabLine,
	opts = {
		disable_winbar_cb = function(args)
			return conditions.buffer_matches({
				buftype = { "nofile", "prompt", "help", "quickfix" },
				filetype = { "^git.*", "fugitive", "Trouble", "dashboard" },
			}, args.buf)
		end,
	},
})