local common = require("user.common")
local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key

keymap("n", "<space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--keymap('v', '<leader>vc', require('osc52').copy_visual)
keymap("t", "<Esc>", "<C-\\><C-n>", term_opts)

-- insert mode
keymap("i", "<M-o>", "<Esc>o", opts)
keymap("i", "<M-n>", "<Esc>", opts)
keymap("n", "<M-n>", "<Esc>", opts)
keymap("v", "<M-n>", "<Esc>", opts)
keymap("c", "<M-n>", "<Esc>", opts)
keymap("t", "<M-n>", "<C-\\><C-n>", opts)
keymap("i", "<M-l>", "<Right>", opts)
keymap("i", "<M-j>", "<Down>", opts)
keymap("i", "<M-k>", "<Up>", opts)
keymap("i", "<M-h>", "<Left>", opts)
keymap("i", "<M-i>", "<Esc>I", opts)
keymap("i", "<M-e>", "<Esc>ea", opts)
keymap("i", "<M-;>", "<Esc>A", opts)
keymap("i", "<M-w>", "<Esc>wa", opts)
keymap("i", "<M-b>", "<Esc>bi", opts)
keymap("i", "<M-c>;", "<Esc>c$", opts)
keymap("i", "<M-enter>;", "<Esc>$a<enter>", opts)

local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
    return
end

local n_opts = {
    mode = "n",
    prefix = "<leader>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}
local v_opts = {
    mode = "v",
    prefix = "<leader>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}
function rename_current_file()
    -- 获取当前文件的完整路径
    local old_path = vim.fn.expand('%:p')
    -- 询问新文件名
    local new_name = vim.fn.input('New Name: ', vim.fn.expand('%:t'), 'file')
    if new_name == "" then
        print("Rename cancelled.")
        return
    end
    -- 构建新的文件路径
    local new_path = vim.fn.fnamemodify(old_path, ':h') .. '/' .. new_name
    -- 重命名文件
    local success, err = os.rename(old_path, new_path)
    if not success then
        print("Error renaming file: " .. err)
        return
    end
    -- 更新当前缓冲区的文件路径
    vim.api.nvim_command('e ' .. new_path)
    print("File renamed to " .. new_name)
end

local function toggle_neovide()
    vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
end

local some_thing_keymap = {
    v = {
        name = "Some Thing",
        --l = { "<cmd>noh<cr>", "Cachel HighLight" },
        i = { "<cmd>luafile ~/.config/nvim/init.lua<cr><cmd>Lazy restore<cr>", "reload config" },
        j = { "<cmd>set relativenumber<cr>", "Set Relative Number" },
        k = { "<cmd>set norelativenumber<cr>", "Cancel Relative Number" },
        h = { "<cmd>SymbolsOutline<cr>", "Toggle Symbols" },
        t = { toggle_neovide, "Toggle Neovide" },
        q = { "<cmd>q<cr>", "Close Current Tab" },
        a = { "<cmd>qa<cr>", "Exit" },
        o = { "<cmd>only<cr>", "Only Window" },
        s = { "<cmd>only<cr><cmd>tabo<cr>", "Only Window Only Tab" },
        g = { "<cmd>ToggleTermToggleAll<cr>", "ToggleAllTerm" },
        u = { "<cmd>TroubleToggle<cr>", "Trouble Toggle" },
        r = { "<cmd>LspRestart<cr>", "Lsp Restart" },
        d = { "<cmd>DiffviewOpen<cr>", "Open Diff" },
        c = { "<cmd>DiffviewClose<cr>", "Close Diff" },
        E = { "<cmd>edit %<cr>", "Reload Current File" },
        e = { "<cmd>bufdo edit %<cr>", "Reload All Buffer File" },
        n = { "<cmd>lua = vim.api.nvim_buf_get_name(0)<cr>", "Get File Abs Path" },
        b = { "<cmd>%bd|e#<cr>", "Delete Other Buffers" },
        p = { ":lua vim.fn.setreg('+', vim.fn.expand('%:p'))<CR>", "Copy File Path to Clipboard" },
        l = { rename_current_file, "Rname Current File" },
        m = { ":%bd!|e#|bd#<cr>", "Remove Other Buffer File" },
    },
}

local tele_keymap = {
    f = {
        name = "Telescope",
        f = { "<cmd>Telescope find_files<cr>", "Find Files" },
        F = { "<cmd>lua require('telescope.builtin').find_files({no_ignore=true, hidden=true})<cr>", "Find Files" },
        --g = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
        g = { "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", "Live Grep" },
        k = { "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>", "Live Grep" },
        u = { "<cmd>Telescope dir find_files<cr>", "Dir Find Files" },
        i = { "<cmd>Telescope dir live_grep<cr>", "Dir Live Grep" },
        --G = { "<cmd>lua require('telescope.builtin').live_grep({no_ignore=true})<cr>", "Find Files" },
        b = { "<cmd>Telescope buffers<cr>", "Buffers" },
        h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
        j = { "<cmd>Telescope diagnostics<cr>", "Diagnostics" },
        n = { "<cmd>Telescope command_history<cr>", "Command History" },
        s = { "<cmd>Telescope search_history<cr>", "Search History" },
        m = { "<cmd>Telescope marks<cr>", "Marks" },
        r = { "<cmd>lua require'telescope'.extensions.project.project{} <cr>", "Recent Project History" },
        p = { "<cmd>Telescope jumplist<cr>", "Jumplist" },
        l = { "<cmd>Telescope file_browser<cr>", "File Browser" },
        o = { "<cmd>Telescope projects<cr>", "Recent Projects" },
        y = { "<cmd>Telescope session-lens<cr>", "Session" },
        t = { "<cmd>Telescope git_status<cr>", "Git status" },
        d = { "<cmd>Telescope commands<cr>", "Commands" },
    },
}

local window_keymap = {
    w = {
        name = "Window",
        h = { "<C-w>h", "Move To Left" },
        l = { "<C-w>l", "Move To Right" },
        j = { "<C-w>j", "Move To Blow" },
        k = { "<C-w>k", "Move To Up" },
        H = { "<C-w>H", "Window Move To Left" },
        L = { "<C-w>L", "Window Move To Right" },
        J = { "<C-w>J", "Window Move To Blow" },
        K = { "<C-w>K", "Window Move To Up" },
        T = { "<C-w>T", "Window Move To New Tab" },
        i = { "<C-w>]<C-w>L", "VSplit And Jump" },
        u = { "<C-w>]", "Split And Jump" },
        t = { "<C-w>]<C-w>T", "Split And Jump" },
    },
}

local zen_keymap = {
    z = {
        name = "Zen Mode",
        n = { "<cmd>TZNarrow<cr>", "Narrow" },
        o = { "<cmd>TZFocus<cr>", "Focus" },
        m = { "<cmd>TZMinimalist<cr>", "Minimalist" },
        i = { "<cmd>TZAtaraxis<cr>", "Ataraxis" },
    },
}

local zen_v_keymap = {
    z = {
        name = "Zen Mode",
        n = { "<cmd>'<,'>TZNarrow<cr>", "Narrow" },
    },
}

local function fold_except_current()
    require("ufo").closeAllFolds()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    --require('ufo').openFold(row)
    local is_foled = vim.fn.foldclosed(row) ~= -1
    if is_foled then
        vim.api.nvim_command(row .. 'foldopen')
    end
end

local ufo_keymap = {
    z = {
        name = "Ufo Fold",
        o = { fold_except_current, "Only Open Current Line" },
        n = { ":lua require('ufo').goNextClosedFold()<cr>", "Go To Next Fold" },
        p = { ":lua require('ufo').goPreviousClosedFold()<cr>", "Go To Pre Fold" },
        h = { ":lua require('ufo').goPreviousStartFold()<cr>", "Go To Fold Start" },
    }
}
local insert_keymap = {
    c = { "<esc>cc", "Delete Line" },
    w = { "<esc>cw", "Delete Word" },
    b = { "<esc>cb", "Delete Pre Word" },
}

local chagpt_keymap = {
    a = {
        name = "ChatGPT",
        c = { "<cmd>ChatGPT<CR>", "ChatGPT" },
        e = { "<cmd>ChatGPTEditWithInstruction<CR>", "Edit with instruction", mode = { "n", "v" } },
        g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction", mode = { "n", "v" } },
        t = { "<cmd>ChatGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
        k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
        d = { "<cmd>ChatGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
        a = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
        p = { "<cmd>ChatGPTRun add_py_tests<CR>", "Add Pytest Tests", mode = { "n", "v" } },
        o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code", mode = { "n", "v" } },
        s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize", mode = { "n", "v" } },
        f = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
        x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code", mode = { "n", "v" } },
        r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit", mode = { "n", "v" } },
        l = { "<cmd>ChatGPTRun code_readability_analysis<CR>", "Code Readability Analysis", mode = { "n", "v" } },
    },
}
local insert_opts = {
    mode = "i",
    prefix = "<M-c>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}
local gpt_opts = {
    mode = { "n", "v" },
    prefix = "<leader>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}


local function test_all()
    local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.loop.getcwd()
    require("neotest").run.run(project_root)
end

local test_keymap = {
    o = {
        name = "Neotest",
        a = { test_all, "Test All" },
        c = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Test Current File" },
        t = { "<cmd>lua require('neotest').stop()<cr>", "Test Stop" },
        f = { "<cmd>Neotest output<cr>", "Show Test Result In Float" },
        e = { "<cmd>Neotest output-panel<cr>", "Show Test Result" },
        d = { "<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", "Debug Current File" },
        --d = { "<cmd>lua require('neotest').diagnostics()<cr>", "Show Test Diagnostics" },
        --s = { "<cmd>lua require('neotest').status.toggle()<cr>", "Status Toggle" },
        s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "summary Toggle" }

    }

}
local chat_opts = gpt_opts

local quick_chat = function()
    local input = vim.fn.input("Quick Chat: ")
    if input ~= "" then
        require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
    end
end
local chat_help_actions = function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.help_actions())
end

local chat_actions = function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
end

--local copilot_chat_mappings = {
--i = {
--name = "CopilotChat",
--c = { "<cmd>CopilotChatTogggle<CR>", "Chat" },
--d = { "<cmd>CopilotChatDebugInfo<CR>", "Debug" },
--q = { quick_chat, "Quick Chat" },
--a = { chat_actions, "Chat Actions" },
--h = { chat_help_actions, "Chat Help Action" },
--x = { "<cmd>CopilotChatExplain<CR>", "Explain Code" },
--t = { "<cmd>CopilotChatTests<CR>", "Add Tests" },
--f = { "<cmd>CopilotChatFix<CR>", "Fix" },
--o = { "<cmd>CopilotChatOptimize<CR>", "Optimize Code" },
--s = { "<cmd>CopilotChatDocs<CR>", "Docs" },
--m = { "<cmd>CopilotChatCommit<CR>", "Git Commit" },
--g = { "<cmd>CopilotChatCommitStaged<CR>", "Git Commit For Staged" },

--}
--}
local lsp_mappings = {
    l = {
        name = "LSP", -- naming the prefix group
        s = { "<cmd>lua vim.lsp.buf.document_symbol()<CR>", "Document Symbols" },
        D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Declaration" },
        d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Definition" },
        I = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation" },
        sh = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
        wa = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add Workspace Folder" },
        wr = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Remove Workspace Folder" },
        wl = { "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", "List Workspace Folders" },
        r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
        c = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
        R = { "<cmd>lua vim.lsp.buf.references()<CR>", "References" },
        f = { "<cmd>lua vim.lsp.buf.format { async = true }<CR>", "Format" },
        -- Note: You have 'lD' defined twice, for 'declaration' and 'type_definition'.
        -- This example keeps the 'type_definition' mapping.
        e = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic Float" },
        q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", "Diagnostic Loclist" },
    },
    ["[d"] = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", "Previous Diagnostic" },
    ["]d"] = { "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", "Next Diagnostic" },
    K = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover" }
}

local lazygit_keymap = {
    s = {
        name = "Lazygit",
        l = { ":LazyGit<cr>", "Lazygit" },
    }
}
which_key.register(some_thing_keymap, n_opts)
which_key.register(tele_keymap, n_opts)
which_key.register(window_keymap, n_opts)
which_key.register(ufo_keymap, n_opts)
which_key.register(lazygit_keymap, n_opts)
--which_key.register(zen_keymap, n_opts)
--which_key.register(zen_v_keymap, v_opts)
which_key.register(insert_keymap, insert_opts)
which_key.register(chagpt_keymap, gpt_opts)
which_key.register(lsp_mappings, gpt_opts)
which_key.register(test_keymap, n_opts)
--which_key.register(copilot_chat_mappings, chat_opts)

for i = 1, 9 do
    local key = string.format("<leader>w%d", i)
    local cmd = string.format("<cmd>%dwincmd w<cr>", i)
    local desc = { desc = string.format("open window%d", i) }
    vim.keymap.set("n", key, cmd, desc)

    local key = string.format("<leader>wc%d", i)
    local cmd = string.format("<cmd>%dwincmd q<cr>", i)
    local desc = { desc = string.format("close window%d", i) }
    vim.keymap.set("n", key, cmd, desc)
end
