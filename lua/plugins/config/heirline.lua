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

-- Rose Pine Dawn color palette (official)
local colors = {
	-- Rose Pine Dawn base colors
	base = "#faf4ed",        -- main background (light)
	surface = "#fffaf3",     -- slightly lighter background
	overlay = "#f2e9e1",     -- overlay background (custom calculated)
	muted = "#9893a5",       -- muted text (official)
	subtle = "#797593",      -- subtle text (official)
	text = "#464261",        -- main text (official)
	
	-- Rose Pine Dawn accent colors (official)
	love = "#b4637a",        -- pink/red
	gold = "#ea9d34",        -- yellow
	rose = "#d7827e",        -- rose
	pine = "#286983",        -- teal
	foam = "#56949f",        -- cyan
	iris = "#907aa9",        -- purple
	leaf = "#6d8f89",        -- leaf green
	
	-- Deep theme backgrounds for statusline
	light_bg = "#1e1e2e",    -- main statusline background (deep gray)
	bright_bg = "#313244",   -- grouped sections background (light gray) 
	clock_bg = "#45475a",    -- clock background (highlight color)
	subtle_bg = "#f7f1ea",   -- subtle sections (kept for tabline)
	
	-- Tab colors using Dawn palette
	tab_active_bg = "#ede4dd",   -- active tab (darker for contrast)
	tab_inactive_bg = "#f4ede8", -- inactive tab (between base and surface)
	tab_border_bg = "#faf4ed",   -- border using base color
	
	-- Dawn text colors
	tab_active_text = "#464261",   -- active tab text (main text color)
	tab_inactive_text = "#797593", -- inactive tab text (subtle)
	statusline_text = "#4A3C3C",   -- statusline text (original deeper brown)
	
	-- Mode-specific backgrounds - colorful for deep theme
	mode_bg = {
		n = "#f38ba8",       -- normal (red)
		i = "#a6e3a1",       -- insert (green)  
		v = "#89b4fa",       -- visual (blue)
		c = "#fab387",       -- command (orange)
		s = "#94e2d5",       -- select (cyan)
		r = "#f9e2af",       -- replace (yellow)
		t = "#f38ba8",       -- terminal (red)
	},
	
	-- Text colors for deep theme
	mode_fg = "#1e1e2e",     -- dark text for colorful mode backgrounds
	bright_fg = "#cdd6f4",   -- bright text for dark backgrounds
	statusline_text = "#cdd6f4", -- bright text for statusline
	gray = "#9893a5",        -- Dawn muted (kept for tabline)
	
	-- Diagnostic colors using Dawn palette
	diag_error = "#b4637a",  -- love (Dawn)
	diag_warn = "#ea9d34",   -- gold (Dawn)
	diag_info = "#286983",   -- pine (Dawn)
	diag_hint = "#56949f",   -- foam (Dawn)
	
	-- Git colors using Dawn palette
	git_add = "#286983",     -- pine (Dawn)
	git_del = "#b4637a",     -- love (Dawn)
	git_change = "#ea9d34",  -- gold (Dawn)
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
	TablinePicker,
	TablineFileNameBlock,
	TablineCloseButton,
})

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
	hl = { bg = colors.tab_border_bg, fg = colors.tab_active_text },  -- subtle border background
	TabLineOffset, BufferLine, TabPages 
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