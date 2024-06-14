local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local keymap = {
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
        e = { "<cmd>Telescope oldfiles<cr>", "Recent Files" },
        y = { "<cmd>Telescope session-lens<cr>", "Session" },
        t = { "<cmd>Telescope git_status<cr>", "Git status" },
        d = { "<cmd>Telescope commands<cr>", "Commands" },
    },
}
require("which-key").register(keymap, normal_opts)
