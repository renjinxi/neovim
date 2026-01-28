-- 所有快捷键集中在此文件定义，方便查看和避免冲突
-- ============================================================================
local M = {}

-- ============================================================================
-- 辅助函数引用
-- ============================================================================
local fn = require("plugins.keymaps.functions")

-- ============================================================================
-- 所有 Keymap 定义
-- 按前缀分组，便于查看冲突
-- ============================================================================
M.mappings = {
	-- ========================================================================
	-- <leader>a - REST Client / Android (冲突！需要按文件类型区分)
	-- ========================================================================
	{ "<leader>a", group = "REST/Android" },
	-- REST Client
	{ "<leader>ao", "<cmd>Rest open<cr>", desc = "REST: Open result pane" },
	{ "<leader>aa", "<cmd>Rest run<cr>", desc = "REST: Run request" },
	{ "<leader>an", "<cmd>Rest run ", desc = "REST: Run with name" },
	{ "<leader>al", "<cmd>Rest last<cr>", desc = "REST: Run last" },
	{ "<leader>ag", "<cmd>Rest logs<cr>", desc = "REST: Edit logs" },
	{ "<leader>ac", "<cmd>Rest cookies<cr>", desc = "REST: Edit cookies" },
	{ "<leader>as", "<cmd>Rest env show<cr>", desc = "REST: Show env" },
	{ "<leader>ae", "<cmd>Rest env select<cr>", desc = "REST: Select env" },
	{ "<leader>at", "<cmd>Rest env set ", desc = "REST: Set env path" },
	-- Android (通过 fn 引用)
	{ "<leader>ad", fn.android_adb_picker, desc = "Android: ADB Commands" },
	-- { "<leader>ag", fn.android_gradle_picker, desc = "Android: Gradle Tasks" }, -- 与 REST logs 冲突
	-- { "<leader>al", fn.android_show_error_log, desc = "Android: View Error Log" }, -- 与 REST last 冲突

	-- ========================================================================
	-- <leader>b - Messages
	-- ========================================================================
	{ "<leader>b", group = "Messages" },
	{ "<leader>ba", "<cmd>messages<CR>", desc = "All Messages" },
	{ "<leader>bl", "<cmd>echo v:statusmsg<CR>", desc = "Last Message" },

	-- ========================================================================
	-- <leader>d - Debug (DAP)
	-- ========================================================================
	{ "<leader>d", group = "Debug" },
	{ "<leader>dC", fn.dap_conditional_breakpoint, desc = "Conditional Breakpoint" },
	{ "<leader>dE", fn.dap_eval_input, desc = "Evaluate Input" },
	{ "<leader>dL", "<cmd>lua require'dap'.run_last()<cr>", desc = "Run Last" },
	{ "<leader>dR", "<cmd>lua require'dap'.run_to_cursor()<cr>", desc = "Run to Cursor" },
	{ "<leader>dS", "<cmd>lua require'dap.ui.widgets'.scopes()<cr>", desc = "Scopes" },
	{ "<leader>dU", fn.dap_toggle_ui, desc = "Toggle UI" },
	{ "<leader>dX", fn.dap_restart, desc = "Restart Debug" },
	{ "<leader>das", fn.dap_enable_all_breakpoints, desc = "Enable All Breakpoints" },
	{ "<leader>dat", fn.dap_disable_all_breakpoints, desc = "Disable All Breakpoints" },
	{ "<leader>db", "<cmd>lua require'dap'.step_back()<cr>", desc = "Step Back" },
	{ "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", desc = "Continue" },
	{ "<leader>dd", "<cmd>lua require'dap'.disconnect()<cr>", desc = "Disconnect" },
	{ "<leader>de", "<cmd>lua require'dapui'.eval()<cr>", desc = "Evaluate" },
	{ "<leader>dg", "<cmd>lua require'dap'.session()<cr>", desc = "Get Session" },
	{ "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", desc = "Hover Variables" },
	{ "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", desc = "Step Into" },
	{ "<leader>dl", fn.dap_clear_all_breakpoints, desc = "Clear All Breakpoints" },
	{ "<leader>dn", "<cmd>lua require'dap'.step_over()<cr>", desc = "Step Over" },
	{ "<leader>dp", "<cmd>lua require'dap'.pause.toggle()<cr>", desc = "Pause" },
	{ "<leader>dq", "<cmd>lua require'dap'.close()<cr>", desc = "Quit" },
	{ "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr><C-w>H", desc = "Toggle Repl" },
	{ "<leader>ds", "<cmd>lua require'dap'.continue()<cr>", desc = "Start" },
	{ "<leader>dt", fn.dap_toggle_breakpoint, desc = "Toggle Breakpoint" },
	{ "<leader>du", "<cmd>lua require'dap'.step_out()<cr>", desc = "Step Out" },
	{ "<leader>dx", "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate" },
	-- Visual mode
	{ "<leader>e", "<cmd>lua require'dapui'.eval()<cr>", desc = "Evaluate", mode = "v" },

	-- ========================================================================
	-- <leader>c - Claude Float (智能避让布局)
	-- ========================================================================
	{ "<leader>c", group = "Claude Float" },
	{ "<leader>cf1", fn.claude_float_1_toggle, desc = "Claude Float 1" },
	{ "<leader>cf2", fn.claude_float_2_toggle, desc = "Claude Float 2" },
	{ "<leader>cf3", fn.claude_float_3_toggle, desc = "Claude Float 3" },
	{ "<leader>cf4", fn.claude_float_4_toggle, desc = "Claude Float 4" },
	{ "<leader>cfn", fn.claude_float_nvim_toggle, desc = "Claude [nvim config]" },
	{ "<leader>cfk", fn.claude_float_kitty_toggle, desc = "Claude [kitty config]" },
	{ "<leader>cfa", fn.claude_float_toggle_all, desc = "Toggle All Claude" },
	{ "<leader>cfs", fn.float_toggle_api_select, desc = "Toggle API Select" },
	{ "<leader>cfh", fn.claude_half_screen_toggle, desc = "Claude Half Screen" },

	-- ========================================================================
	-- <leader>ct - Terminal Float (智能避让布局)
	-- ========================================================================
	{ "<leader>ct", group = "Terminal Float" },
	{ "<leader>ct1", fn.term_float_1_toggle, desc = "Terminal Float 1" },
	{ "<leader>ct2", fn.term_float_2_toggle, desc = "Terminal Float 2" },
	{ "<leader>ct3", fn.term_float_3_toggle, desc = "Terminal Float 3" },
	{ "<leader>ct4", fn.term_float_4_toggle, desc = "Terminal Float 4" },
	{ "<leader>cta", fn.term_float_toggle_all, desc = "Toggle All Terminal" },

	-- ========================================================================
	-- <leader>f - Telescope (Find)
	-- ========================================================================
	{ "<leader>f", group = "Telescope" },
	{ "<leader>fF", "<cmd>lua require('telescope.builtin').find_files({no_ignore=true, hidden=true})<cr>", desc = "Find Files (all)" },
	{ "<leader>fG", "<cmd>Telescope live_grep<cr>", desc = "Builtin Live Grep" },
	-- Dotfiles 快速访问 (~/dotfiles: claude, nvim, kitty, notes)
	{
		"<leader>fv",
		function()
			require("fzf-lua").files({
				prompt = "Dotfiles> ",
				cwd = vim.fn.expand("~/dotfiles"),
			})
		end,
		desc = "Dotfiles",
	},
	{
		"<leader>fw",
		function()
			require("fzf-lua").live_grep({
				prompt = "Grep Dotfiles> ",
				cwd = vim.fn.expand("~/dotfiles"),
			})
		end,
		desc = "Grep Dotfiles",
	},
	{ "<leader>fa", "<cmd>Telescope neoclip<cr>", desc = "NeoClip" },
	{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
	{ "<leader>fc", fn.telescope_copy_file_content, desc = "Copy File Content" },
	{ "<leader>fd", "<cmd>Telescope commands<cr>", desc = "Commands" },
	{ "<leader>fe", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
	{ "<leader>fg", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", desc = "Live Grep" },
	{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
	{ "<leader>fi", "<cmd>Telescope dir live_grep<cr>", desc = "Dir Live Grep" },
	{ "<leader>fj", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
	{ "<leader>fk", "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>", desc = "Grep Word" },
	{ "<leader>fl", "<cmd>Telescope file_browser<cr>", desc = "File Browser" },
	{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
	{ "<leader>fn", "<cmd>Telescope command_history<cr>", desc = "Command History" },
	{ "<leader>fo", "<cmd>Telescope projects<cr>", desc = "Recent Projects" },
	{ "<leader>fp", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
	{ "<leader>fr", "<cmd>Telescope projects<cr>", desc = "Recent Project History" },
	{ "<leader>fs", "<cmd>Telescope search_history<cr>", desc = "Search History" },
	{ "<leader>ft", "<cmd>Telescope git_status<cr>", desc = "Git status" },
	{ "<leader>fu", "<cmd>Telescope dir find_files<cr>", desc = "Dir Find Files" },
	{ "<leader>fy", "<cmd>Telescope session-lens<cr>", desc = "Session" },
	{ "<leader>fz", "<cmd>Telescope keymaps<cr>", desc = "Search Keymaps" },

	-- ========================================================================
	-- <leader>g - Terminal
	-- ========================================================================
	{ "<leader>g", group = "Terminal" },
	{ "<leader>ga", fn.terminal_lua_toggle, desc = "Lua" },
	{ "<leader>gc", fn.claude_launcher, desc = "Claude Launcher (灵活)" },
	{ "<leader>gc1", function() fn.tab_terminal_claude(1) end, desc = "Claude Code API 1" },
	{ "<leader>gc2", function() fn.tab_terminal_claude(2) end, desc = "Claude Code API 2" },
	{ "<leader>gcn", fn.tab_terminal_claude_new, desc = "New Claude Code Tab" },
	{ "<leader>gcn1", function() fn.tab_terminal_claude_new(1) end, desc = "New Claude Tab (API 1)" },
	{ "<leader>gcn2", function() fn.tab_terminal_claude_new(2) end, desc = "New Claude Tab (API 2)" },
	{ "<leader>gd", fn.tab_terminal_codex, desc = "Codex" },
	{ "<leader>gg", fn.terminal_cursor_agent_toggle, desc = "Cursor Agent" },
	{ "<leader>gh", fn.terminal_htop_toggle, desc = "Htop" },
	{ "<leader>gi", fn.terminal_ipython_toggle, desc = "IPython" },
	{ "<leader>gk", fn.terminal_kimi_claude_code_toggle, desc = "Kimi Claude Code" },
	{ "<leader>gl", fn.terminal_gemini_toggle, desc = "Gemini" },
	{ "<leader>gn", fn.terminal_newterm_toggle, desc = "New Term" },
	{ "<leader>gq", fn.terminal_qwen_toggle, desc = "Qwen" },
	{ "<leader>gr", fn.terminal_newsboat_toggle, desc = "Newsboat" },
	{ "<leader>gt", fn.terminal_newterm_tab, desc = "New Tab Term" },
	{ "<leader>gu", fn.terminal_ncdu_toggle, desc = "Ncdu" },

	-- ========================================================================
	-- <leader>i - FzfLua
	-- ========================================================================
	{ "<leader>i", group = "FzfLua" },
	{ "<leader>if", ":FzfLua files<cr>", desc = "Find Files" },
	{ "<leader>ig", ":FzfLua live_grep<cr>", desc = "Live Grep" },
	{ "<leader>ib", ":FzfLua buffers<cr>", desc = "Buffers" },
	{ "<leader>id", ":FzfLua commands<cr>", desc = "Commands" },
	{ "<leader>ie", ":FzfLua oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>ih", ":FzfLua help_tags<cr>", desc = "Help Tags" },
	{ "<leader>ii", ":FzfLua dir live_grep<cr>", desc = "Dir Live Grep" },
	{ "<leader>ij", ":FzfLua diagnostics<cr>", desc = "Diagnostics" },
	{ "<leader>ik", "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>", desc = "Grep Word" },
	{ "<leader>il", ":FzfLua file_browser<cr>", desc = "File Browser" },
	{ "<leader>im", ":FzfLua marks<cr>", desc = "Marks" },
	{ "<leader>in", ":FzfLua command_history<cr>", desc = "Command History" },
	{ "<leader>io", ":FzfLua projects<cr>", desc = "Recent Projects" },
	{ "<leader>ip", ":FzfLua jumplist<cr>", desc = "Jumplist" },
	{ "<leader>ir", "<cmd>lua require'telescope'.extensions.project.project{}<cr>", desc = "Project History" },
	{ "<leader>is", ":FzfLua search_history<cr>", desc = "Search History" },
	{ "<leader>it", ":FzfLua git_status<cr>", desc = "Git status" },
	{ "<leader>iu", ":FzfLua dir find_files<cr>", desc = "Dir Find Files" },
	{ "<leader>iy", ":FzfLua session-lens<cr>", desc = "Session" },

	-- ========================================================================
	-- <leader>j - goto_preview
	-- ========================================================================
	{ "<leader>j", group = "goto_preview" },
	{ "<leader>jc", "<cmd>lua require('goto-preview').close_all_win()<CR>", desc = "Close all" },
	{ "<leader>jd", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", desc = "Definition" },
	{ "<leader>ji", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", desc = "Implementation" },
	{ "<leader>jr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>", desc = "References" },
	{ "<leader>jt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", desc = "Type Definition" },

	-- ========================================================================
	-- <leader>K, <leader>[d, <leader>]d - LSP Quick
	-- ========================================================================
	{ "<leader>K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover" },
	{ "<leader>[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "Previous Diagnostic" },
	{ "<leader>]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "Next Diagnostic" },

	-- ========================================================================
	-- <leader>l - LSP / LeetCode (冲突！)
	-- ========================================================================
	{ "<leader>l", group = "LSP/LeetCode" },
	-- LSP
	{ "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "LSP: Declaration" },
	{ "<leader>lI", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "LSP: Implementation" },
	{ "<leader>lR", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "LSP: References" },
	{ "<leader>la", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "LSP: Find References" },
	{ "<leader>lc", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "LSP: Code Action" },
	{ "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "LSP: Definition" },
	{ "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "LSP: Diagnostic Float" },
	{ "<leader>lf", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", desc = "LSP: Format" },
	{ "<leader>lg", "<cmd>Telescope lsp_outgoing_calls<CR>", desc = "LSP: Outgoing Calls" },
	{ "<leader>li", "<cmd>Telescope lsp_incoming_calls<CR>", desc = "LSP: Incoming Calls" },
	{ "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<CR>", desc = "LSP: Diagnostic Loclist" },
	{ "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "LSP: Rename" },
	{ "<leader>ls", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", desc = "LSP: Document Symbols" },
	{ "<leader>lsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "LSP: Signature Help" },
	{ "<leader>lwa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", desc = "LSP: Add Workspace Folder" },
	{ "<leader>lwl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", desc = "LSP: List Workspace Folders" },
	{ "<leader>lwr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", desc = "LSP: Remove Workspace Folder" },

	-- ========================================================================
	-- <leader>m - Sessions
	-- ========================================================================
	{ "<leader>m", group = "Sessions" },
	{ "<leader>ms", "<cmd>PossessionSave<cr>", desc = "Save session" },
	{ "<leader>ml", "<cmd>PossessionLoad<cr>", desc = "Load session" },
	{ "<leader>md", "<cmd>PossessionDelete<cr>", desc = "Delete session" },
	{ "<leader>mc", "<cmd>PossessionClose<cr>", desc = "Close session" },
	{ "<leader>mh", "<cmd>PossessionList<cr>", desc = "List sessions" },
	{ "<leader>mr", "<cmd>PossessionRename<cr>", desc = "Rename session" },
	{ "<leader>mi", "<cmd>PossessionShow<cr>", desc = "Show current session" },
	{ "<leader>mw", fn.session_save_workspace, desc = "Save workspace session" },
	{ "<leader>mW", fn.session_load_workspace, desc = "Load workspace session" },
	{ "<leader>mD", fn.session_delete_workspace, desc = "Delete workspace session" },
	{ "<leader>mm", fn.session_list_workspace, desc = "Select session" },
	{ "<leader>mt", fn.session_telescope, desc = "Telescope sessions" },

	-- ========================================================================
	-- <leader>e - Email (aerc)
	-- ========================================================================
	{ "<leader>e", group = "Email" },
	{ "<leader>ea", fn.mail_aerc, desc = "Open aerc" },

	-- ========================================================================
	-- <leader>o - Neotest
	-- ========================================================================
	{ "<leader>o", group = "Neotest" },
	{ "<leader>oa", fn.neotest_all, desc = "Test All" },
	{ "<leader>oc", "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", desc = "Test Current File" },
	{ "<leader>od", "<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", desc = "Debug Current File" },
	{ "<leader>oe", "<cmd>Neotest output-panel<cr>", desc = "Show Test Result" },
	{ "<leader>of", "<cmd>Neotest output<cr>", desc = "Show Result Float" },
	{ "<leader>os", "<cmd>lua require('neotest').summary.toggle()<cr>", desc = "Summary Toggle" },
	{ "<leader>ot", "<cmd>lua require('neotest').stop()<cr>", desc = "Test Stop" },

	-- ========================================================================
	-- <leader>p - Project
	-- ========================================================================
	{ "<leader>p", group = "Project" },
	{ "<leader>pp", "<cmd>Telescope projects<cr>", desc = "List Projects" },
	{ "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
	{ "<leader>ps", "<cmd>Telescope live_grep<cr>", desc = "Search in Project" },
	{ "<leader>pr", fn.project_reset_root, desc = "Reset Project Root" },
	{ "<leader>pm", fn.project_manual_set_root, desc = "Manually Set Root" },

	-- ========================================================================
	-- <leader>r - Overseer (Run)
	-- ========================================================================
	{ "<leader>r", group = "Overseer" },
	{ "<leader>rl", ":OverseerRestartLast<cr>", desc = "Restart Last Task" },
	{ "<leader>ro", ":OverseerQuickAction<cr>", desc = "Quick Action" },
	{ "<leader>rr", ":OverseerRun<cr>", desc = "Run" },
	{ "<leader>rm", ":OverseerRunMulti<cr>", desc = "Run Multi" },
	{ "<leader>rp", ":OverseerRunLast<cr>", desc = "Run Previous" },
	{ "<leader>rg", ":OverseerToggle<cr>", desc = "Toggle" },
	{ "<leader>rb", fn.overseer_go_build, desc = "Go Build" },
	{ "<leader>rs", fn.overseer_run_script, desc = "Run Script" },
	{ "<leader>ra", fn.overseer_run_script_args, desc = "Run Script with Args" },

	-- ========================================================================
	-- <leader>s - Git (Source control)
	-- ========================================================================
	{ "<leader>s", group = "Git" },
	{ "<leader>sg", ":Neogit<cr>", desc = "Neogit" },
	{ "<leader>sl", ":LazyGit<cr>", desc = "LazyGit (current)" },
	{ "<leader>sL", fn.git_lazygit_multi_repo, desc = "LazyGit (select repo)" },
	{ "<leader>sk", fn.git_lazygit_last_repo, desc = "LazyGit (last repo)" },
	{ "<leader>sf", ":Git<cr>", desc = "Fugitive" },
	{ "<leader>sa", ":Git add %<cr>", desc = "Add Current File" },
	{ "<leader>sA", ":Git add .<cr>", desc = "Add All Files" },
	{ "<leader>sm", ":Git commit<cr>", desc = "Commit" },
	{ "<leader>sd", ":Git diff %<cr>", desc = "Diff Current File" },
	{ "<leader>si", ":Git diff .<cr>", desc = "Diff All Files" },
	{ "<leader>sD", ":Git diff --cached %<cr>", desc = "Diff Staged" },
	{ "<leader>so", ":Git log<cr>", desc = "Git Log" },
	{ "<leader>sv", ":DiffviewOpen<cr>", desc = "DiffView" },
	{ "<leader>sc", ":DiffviewFileHistory<cr>", desc = "File History" },
	{ "<leader>sp", ":Git pull --rebase<cr>", desc = "Pull Rebase" },
	{ "<leader>sP", ":Git push<cr>", desc = "Push" },
	{ "<leader>sn", function() require('gitsigns').next_hunk() end, desc = "Next Hunk" },
	{ "<leader>sb", function() require('gitsigns').prev_hunk() end, desc = "Prev Hunk" },
	{ "<leader>ss", function() require('gitsigns').stage_hunk() end, desc = "Stage Hunk" },
	{ "<leader>sr", function() require('gitsigns').reset_hunk() end, desc = "Reset Hunk" },
	{ "<leader>su", function() require('gitsigns').undo_stage_hunk() end, desc = "Undo Stage Hunk" },
	{ "<leader>sh", function() require('gitsigns').preview_hunk() end, desc = "Preview Hunk" },
	{ "<leader>sB", function() require('gitsigns').blame_line{full=true} end, desc = "Blame Line" },
	{ "<leader>st", function() require('gitsigns').toggle_current_line_blame() end, desc = "Toggle Line Blame" },
	{ "<leader>sT", function() require('gitsigns').toggle_deleted() end, desc = "Toggle Deleted" },
	{ "<leader>se", fn.git_compare_head, desc = "Compare with HEAD" },
	{ "<leader>sv", fn.show_multi_repo_branches, desc = "View Multi-Repo Branches" },

	-- ========================================================================
	-- <leader>t - Tree / Tab
	-- ========================================================================
	{ "<leader>t", group = "Tree/Tab" },
	{ "<leader>tt", "<cmd>NvimTreeToggle<cr>", desc = "Toggle Tree" },
	{ "<leader>tl", fn.nvim_tree_float, desc = "Float Tree" },
	{ "<leader>tf", "<cmd>NvimTreeFocus<cr>", desc = "Focus Tree" },
	{ "<leader>tr", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file" },
	{ "<leader>tc", "<cmd>NvimTreeClose<cr>", desc = "Close Tree" },
	{ "<leader>tn", fn.tab_rename, desc = "Rename Tab" },
	{ "<leader>tx", fn.tab_clear_name, desc = "Clear Tab Name" },
	{ "<leader>tu", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },

	-- ========================================================================
	-- <leader>v - Various (Some Thing)
	-- ========================================================================
	{ "<leader>v", group = "Various" },
	{ "<leader>va", "<cmd>qa<cr>", desc = "Exit" },
	{ "<leader>vb", "<cmd>%bd|e#<cr>", desc = "Delete Other Buffers" },
	{ "<leader>vc", "<cmd>DiffviewClose<cr>", desc = "Close Diff" },
	{ "<leader>vd", fn.diffview_multi_repo, desc = "Multi-Repo Changes" },
	{ "<leader>vD", "<cmd>DiffviewOpen<cr>", desc = "Open Diff (current)" },
	{ "<leader>ve", "<cmd>bufdo edit %<cr>", desc = "Reload All Buffers" },
	{ "<leader>vf", "<cmd>ASToggle<cr>", desc = "Toggle Auto Save" },
	{ "<leader>vh", fn.toggle_hlsearch, desc = "Toggle Hlsearch" },
	{ "<leader>vi", fn.reload_config, desc = "Reload Neovim Config" },
	{ "<leader>vlr", fn.rename_current_file, desc = "Rename Current File" },
	{ "<leader>vla", fn.create_new_file, desc = "Create New File" },
	{ "<leader>vm", ":%bd!|e#|bd#<cr>", desc = "Remove Other Buffers" },
	{ "<leader>vo", "<cmd>only<cr>", desc = "Only Window" },
	{ "<leader>vp", fn.copy_file_path, desc = "Copy File Path" },
	{ "<leader>vq", "<cmd>q<cr>", desc = "Close Current Tab" },
	{ "<leader>vr", "<cmd>LspRestart<cr>", desc = "Lsp Restart" },
	{ "<leader>vs", "<cmd>only<cr><cmd>tabo<cr>", desc = "Only Window/Tab" },
	{ "<leader>vu", ":UndotreeToggle<cr>", desc = "Undo Tree Toggle" },
	{ "<leader>vv", fn.open_project_in_new_tab, desc = "Open Project In New Tab" },
	{ "<leader>vw", ":DiffviewFileHistory %<cr>", desc = "File History" },
	{ "<leader>vz", ":ZenMode<cr>", desc = "Toggle Zen Mode" },
	{ "<leader>vx", fn.copy_message, desc = "Copy Message" },
	{ "<leader>vxl", fn.copy_last_message, desc = "Copy Last Message" },
	{ "<leader>vxa", fn.copy_all_messages, desc = "Copy All Messages" },
	{ "<leader>yw", fn.copy_word_with_location, desc = "Copy Word with Location" },
	{ "<leader>yl", fn.copy_selection_with_location, desc = "Copy with Location", mode = { "n", "v" } },

	-- ========================================================================
	-- <leader>w - Window
	-- ========================================================================
	{ "<leader>w", group = "Window" },
	{ "<leader>wH", "<C-w>H", desc = "Move To Left" },
	{ "<leader>wJ", "<C-w>J", desc = "Move To Below" },
	{ "<leader>wK", "<C-w>K", desc = "Move To Up" },
	{ "<leader>wL", "<C-w>L", desc = "Move To Right" },
	{ "<leader>wT", "<C-w>T", desc = "Move To New Tab" },
	{ "<leader>wh", "<C-w>h", desc = "Go Left" },
	{ "<leader>wi", "<C-w>]<C-w>L", desc = "VSplit And Jump" },
	{ "<leader>wj", "<C-w>j", desc = "Go Below" },
	{ "<leader>wk", "<C-w>k", desc = "Go Up" },
	{ "<leader>wl", "<C-w>l", desc = "Go Right" },
	{ "<leader>wm", ":tabmove<cr>", desc = "Move Tab To Last" },
	{ "<leader>wt", "<C-w>]<C-w>T", desc = "Split And Jump Tab" },
	{ "<leader>wu", "<C-w>]", desc = "Split And Jump" },

	-- ========================================================================
	-- <leader>x - Trouble / Quickfix
	-- ========================================================================
	{ "<leader>x", group = "Trouble/Quickfix" },
	{ "<leader>xj", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
	{ "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions" },
	{ "<leader>xm", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
	{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
	{ "<leader>xu", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
	{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
	-- Quickfix 导航
	{ "<leader>xn", "<cmd>cnext<cr>", desc = "Next Quickfix" },
	{ "<leader>xp", "<cmd>cprev<cr>", desc = "Prev Quickfix" },
	{ "<leader>xo", "<cmd>copen<cr>", desc = "Open Quickfix" },
	{ "<leader>xc", "<cmd>cclose<cr>", desc = "Close Quickfix" },

	-- ========================================================================
	-- <leader>z - Ufo Fold
	-- ========================================================================
	{ "<leader>z", group = "Fold" },
	{ "<leader>zh", ":lua require('ufo').goPreviousStartFold()<cr>", desc = "Go To Fold Start" },
	{ "<leader>zi", fn.ufo_focus_next_fold, desc = "Focus Next Fold" },
	{ "<leader>zn", ":lua require('ufo').goNextClosedFold()<cr>", desc = "Go To Next Fold" },
	{ "<leader>zo", fn.ufo_fold_except_current, desc = "Only Open Current" },
	{ "<leader>zp", ":lua require('ufo').goPreviousClosedFold()<cr>", desc = "Go To Prev Fold" },

	-- ========================================================================
	-- <leader>q - Database (Query)
	-- ========================================================================
	{ "<leader>q", group = "Database" },
	{ "<leader>qu", "<cmd>DBUIToggle<cr>", desc = "Toggle DBUI" },
	{
		"<leader>qs",
		function()
			require("fzf-lua").files({
				prompt = "SQL Queries> ",
				cwd = vim.fn.stdpath("data") .. "/db_ui",
				fd_opts = "--type f --extension sql",
			})
		end,
		desc = "Search SQL Files",
	},
	{
		"<leader>qg",
		function()
			require("fzf-lua").live_grep({
				prompt = "Grep SQL> ",
				cwd = vim.fn.stdpath("data") .. "/db_ui",
				glob = "*.sql",
			})
		end,
		desc = "Grep in SQL Files",
	},

	-- ========================================================================
	-- <leader>ar - Animation (Cellular Automaton)
	-- ========================================================================
	{ "<leader>ar", group = "Animation" },
	{ "<leader>arr", "<cmd>CellularAutomaton make_it_rain<cr>", desc = "Rain" },
	{ "<leader>arg", "<cmd>CellularAutomaton game_of_life<cr>", desc = "Game of Life" },
	{ "<leader>ars", "<cmd>CellularAutomaton scramble<cr>", desc = "Scramble" },

	-- ========================================================================
	-- <leader>vv - Venv Selector (Python)
	-- ========================================================================
	{ "<leader>vv", group = "Venv" },
	{ "<leader>vvs", "<cmd>VenvSelect<cr>", desc = "Select Venv" },
	{ "<leader>vvc", "<cmd>VenvSelectCached<cr>", desc = "Select Cached" },
	{ "<leader>vvu", "<cmd>VenvSelectCurrent<cr>", desc = "Select Current" },
}

-- ============================================================================
-- 非 Leader 键映射
-- ============================================================================
M.non_leader_mappings = {
	-- Flash
	{ "s", function() require("flash").jump() end, desc = "Flash", mode = { "n", "x", "o" } },
	{ "S", function() require("flash").treesitter() end, desc = "Flash Treesitter", mode = { "n", "x", "o" } },
	{ "r", function() require("flash").remote() end, desc = "Remote Flash", mode = "o" },
	{ "R", function() require("flash").treesitter_search() end, desc = "Treesitter Search", mode = { "o", "x" } },
	{ "<c-s>", function() require("flash").toggle() end, desc = "Toggle Flash Search", mode = "c" },

	-- gF - Open path:line
	{ "gF", fn.open_path_at_cursor, desc = "Open path:line under cursor", mode = "n" },

	-- gV - Open file under cursor in vsplit
	{ "gV", "<C-w>vgf", desc = "Open file in vsplit", mode = "n" },

	-- zR, zM, zr - Fold
	{ "zR", function() require("ufo").openAllFolds() end, desc = "Open All Folds", mode = "n" },
	{ "zM", function() require("ufo").closeAllFolds() end, desc = "Close All Folds", mode = "n" },
	{ "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open Folds Except", mode = "n" },
}

-- ============================================================================
-- Ctrl 键映射
-- ============================================================================
M.ctrl_mappings = {
	-- Overseer
	{ "<C-S-r>", "<cmd>OverseerRun<cr>", desc = "Overseer Run", mode = "n" },
	{ "<C-S-t>", "<cmd>OverseerToggle<cr>", desc = "Overseer Toggle", mode = "n" },
	{ "<C-S-l>", "<cmd>OverseerRestartLast<cr>", desc = "Overseer Restart Last", mode = "n" },

	-- LuaSnip
	{ "<C-G>", function() require("luasnip").expand() end, desc = "Expand Snippet", mode = "i" },
	{ "<C-t>", function() require("luasnip").jump(1) end, desc = "Jump Next", mode = { "i", "s" } },
	{ "<C-b>", function() require("luasnip").jump(-1) end, desc = "Jump Prev", mode = { "i", "s" } },
	{ "<C-,>", function() if require("luasnip").choice_active() then require("luasnip").change_choice(1) end end, desc = "Change Choice", mode = { "i", "s" } },
}

-- ============================================================================
-- Window 快速跳转 (动态生成)
-- ============================================================================
M.window_jump_mappings = {}
for i = 1, 9 do
	table.insert(M.window_jump_mappings, {
		"<leader>w" .. i,
		string.format("<cmd>%dwincmd w<cr>", i),
		desc = string.format("Window %d", i),
	})
	table.insert(M.window_jump_mappings, {
		"<leader>wc" .. i,
		string.format("<cmd>%dwincmd q<cr>", i),
		desc = string.format("Close Window %d", i),
	})
end

-- ============================================================================
-- Tab 导航 (动态生成) - Terminal 模式通过 TermOpen autocmd 注册
-- ============================================================================
M.tab_nav_mappings = {}
for i = 1, 9 do
	table.insert(M.tab_nav_mappings, { "<C-" .. i .. ">", i .. "gt", desc = "Tab " .. i, mode = "n" })
	table.insert(M.tab_nav_mappings, { "<C-" .. i .. ">", "<Esc>" .. i .. "gt", desc = "Tab " .. i, mode = "i" })
	table.insert(M.tab_nav_mappings, { "<C-" .. i .. ">", "<Esc>" .. i .. "gt", desc = "Tab " .. i, mode = "v" })
end

-- ============================================================================
-- Alt 键映射 (macOS Option 键)
-- ============================================================================
M.alt_mappings = {
	-- Claude Float (Alt+1~2)
	{ "<A-1>", fn.claude_float_1_toggle, desc = "Claude Float 1", mode = { "n", "i", "v", "t" } },
	{ "<A-2>", fn.claude_float_2_toggle, desc = "Claude Float 2", mode = { "n", "i", "v", "t" } },
	-- Terminal Float (Alt+3~4)
	{ "<A-3>", fn.term_float_1_toggle, desc = "Terminal Float 1", mode = { "n", "i", "v", "t" } },
	{ "<A-4>", fn.term_float_2_toggle, desc = "Terminal Float 2", mode = { "n", "i", "v", "t" } },
	{ "<A-n>", fn.claude_float_nvim_toggle, desc = "Claude [nvim]", mode = { "n", "i", "v", "t" } },
	{ "<A-k>", fn.claude_float_kitty_toggle, desc = "Claude [kitty]", mode = { "n", "i", "v", "t" } },
	{ "<A-a>", fn.float_hide_all, desc = "Hide All Float", mode = { "n", "i", "v", "t" } },
	-- 窗口跳转 (Alt+5~9)
	{ "<A-5>", "<cmd>5wincmd w<cr>", desc = "Window 5", mode = { "n", "i", "v", "t" } },
	{ "<A-6>", "<cmd>6wincmd w<cr>", desc = "Window 6", mode = { "n", "i", "v", "t" } },
	{ "<A-7>", "<cmd>7wincmd w<cr>", desc = "Window 7", mode = { "n", "i", "v", "t" } },
	{ "<A-8>", "<cmd>8wincmd w<cr>", desc = "Window 8", mode = { "n", "i", "v", "t" } },
	{ "<A-9>", "<cmd>9wincmd w<cr>", desc = "Window 9", mode = { "n", "i", "v", "t" } },
	-- 字母键快捷操作
	{ "<A-s>", "<cmd>w<cr>", desc = "Quick Save", mode = { "n", "i" } },
	{ "<A-q>", "<cmd>q<cr>", desc = "Quick Quit", mode = "n" },
	{ "<A-w>", "<cmd>bdelete<cr>", desc = "Close Buffer", mode = "n" },
	{ "<A-t>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle Tree", mode = { "n", "i", "v", "t" } },
	{ "<A-g>", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer", mode = { "n", "i", "v", "t" } },
	{ "<A-l>", "<cmd>OverseerRestartLast<cr>", desc = "Restart Last", mode = { "n", "i", "v", "t" } },
}

-- ============================================================================
-- Terminal 模式特殊键 (通过 TermOpen autocmd 注册，见 config/terminal.lua)
-- ============================================================================

-- ============================================================================
-- Insert 模式 Tab 导航
-- ============================================================================
M.insert_tab_mappings = {
	{ "gt", "<Esc>gt", desc = "Next Tab", mode = "i" },
	{ "gT", "<Esc>gT", desc = "Prev Tab", mode = "i" },
}

-- ============================================================================
-- 注册函数
-- ============================================================================
function M.setup()
	local wk = require("which-key")

	-- 注册主要 leader 键映射
	wk.add(M.mappings)

	-- 注册 window 跳转映射
	wk.add(M.window_jump_mappings)

	-- 注册非 leader 键映射
	for _, map in ipairs(M.non_leader_mappings) do
		local mode = map.mode or "n"
		vim.keymap.set(mode, map[1], map[2], { desc = map.desc, silent = true })
	end

	-- 注册 Ctrl 键映射
	for _, map in ipairs(M.ctrl_mappings) do
		local mode = map.mode or "n"
		vim.keymap.set(mode, map[1], map[2], { desc = map.desc, silent = true })
	end

	-- 注册 Tab 导航映射
	for _, map in ipairs(M.tab_nav_mappings) do
		vim.keymap.set(map.mode, map[1], map[2], { desc = map.desc, silent = true })
	end

	-- 注册 Alt 键映射
	for _, map in ipairs(M.alt_mappings) do
		local modes = type(map.mode) == "table" and map.mode or { map.mode }
		for _, mode in ipairs(modes) do
			vim.keymap.set(mode, map[1], map[2], { desc = map.desc, silent = true })
		end
	end

	-- 注册 Insert 模式 Tab 映射
	for _, map in ipairs(M.insert_tab_mappings) do
		vim.keymap.set(map.mode, map[1], map[2], { desc = map.desc, silent = true })
	end

	-- 创建 Claude 启动器命令
	-- 简化版：直接用命令名指定显示方式
	local function create_claude_term(api_num, display_type)
		local env_mod = require("core.env")
		local cmd
		if api_num then
			local base_url = env_mod.get("CLAUDE_API" .. api_num .. "_BASE_URL") or ""
			local token = env_mod.get("CLAUDE_API" .. api_num .. "_TOKEN") or ""
			if base_url ~= "" and token ~= "" then
				cmd = string.format("ANTHROPIC_BASE_URL=%s ANTHROPIC_AUTH_TOKEN=%s claude", base_url, token)
			else
				cmd = "claude"
			end
		else
			cmd = "claude"
		end

		local env = vim.fn.environ()
		env.PATH = vim.fn.expand("$HOME/.local/bin") .. ":" .. vim.fn.expand("$HOME/.nvm/versions/node/v22.12.0/bin") .. ":" .. (env.PATH or "")

		if display_type == "tab" then
			vim.cmd("tabnew")
			vim.fn.termopen(cmd, { env = env })
			vim.cmd("startinsert")
		elseif display_type == "float" then
			local width = math.floor(vim.o.columns * 0.8)
			local height = math.floor(vim.o.lines * 0.8)
			local buf = vim.api.nvim_create_buf(false, true)
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = width,
				height = height,
				row = math.floor((vim.o.lines - height) / 2),
				col = math.floor((vim.o.columns - width) / 2),
				style = "minimal",
				border = "rounded",
				title = " Claude ",
				title_pos = "center",
			})
			vim.fn.termopen(cmd, { env = env })
			vim.cmd("startinsert")
			vim.keymap.set("n", "q", function()
				if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
			end, { buffer = buf, noremap = true, silent = true })
		elseif display_type == "half" then
			local width = math.floor(vim.o.columns * 0.5)
			local height = vim.o.lines - 4
			local buf = vim.api.nvim_create_buf(false, true)
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = width,
				height = height,
				row = 1,
				col = vim.o.columns - width - 1,
				style = "minimal",
				border = "rounded",
				title = " Claude ",
				title_pos = "center",
			})
			vim.fn.termopen(cmd, { env = env })
			vim.cmd("startinsert")
			vim.keymap.set("n", "q", function()
				if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
			end, { buffer = buf, noremap = true, silent = true })
		elseif display_type == "hsplit" then
			vim.cmd("botright " .. math.floor(vim.o.lines * 0.4) .. "split")
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(0, buf)
			vim.fn.termopen(cmd, { env = env })
			vim.cmd("startinsert")
		elseif display_type == "vsplit" then
			vim.cmd("botright " .. math.floor(vim.o.columns * 0.4) .. "vsplit")
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(0, buf)
			vim.fn.termopen(cmd, { env = env })
			vim.cmd("startinsert")
		end
	end

	-- 创建简洁的命令
	vim.api.nvim_create_user_command("Claude", function() create_claude_term(nil, "tab") end, { desc = "Claude (Tab)" })
	vim.api.nvim_create_user_command("Claude1", function() create_claude_term(1, "tab") end, { desc = "Claude API 1 (Tab)" })
	vim.api.nvim_create_user_command("Claude2", function() create_claude_term(2, "tab") end, { desc = "Claude API 2 (Tab)" })
	vim.api.nvim_create_user_command("ClaudeFloat", function() create_claude_term(nil, "float") end, { desc = "Claude (Float)" })
	vim.api.nvim_create_user_command("ClaudeHalf", function() create_claude_term(nil, "half") end, { desc = "Claude (Half Screen)" })
	vim.api.nvim_create_user_command("ClaudeVsplit", function() create_claude_term(nil, "vsplit") end, { desc = "Claude (Vsplit)" })
	vim.api.nvim_create_user_command("ClaudeHsplit", function() create_claude_term(nil, "hsplit") end, { desc = "Claude (Hsplit)" })

	-- GitLab MR 命令
	vim.api.nvim_create_user_command("MR", function(opts)
		fn.gitlab_create_mr_web(opts.args)
	end, { nargs = 1, desc = "创建 MR 到指定分支", complete = function()
		-- 补全远程分支
		local branches = vim.fn.systemlist("git branch -r --format='%(refname:short)' | sed 's|origin/||'")
		return branches
	end })
end

return M
