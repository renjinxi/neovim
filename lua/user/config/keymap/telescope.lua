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
        --G = { "<cmd>lua require('telescope.builtin').live_grep({no_ignore=true})<cr>", "Find Files" },
        --g = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
        F = { "<cmd>lua require('telescope.builtin').find_files({no_ignore=true, hidden=true})<cr>", "Find Files" },

        a = { "<cmd>Telescope neoclip<cr>", "NeoClip" },
        b = { "<cmd>Telescope buffers<cr>", "Buffers" },
        d = { "<cmd>Telescope commands<cr>", "Commands" },
        e = { "<cmd>Telescope oldfiles<cr>", "Recent Files" },
        f = { "<cmd>Telescope find_files<cr>", "Find Files" },
        g = { "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", "Live Grep" },
        h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
        i = { "<cmd>Telescope dir live_grep<cr>", "Dir Live Grep" },
        j = { "<cmd>Telescope diagnostics<cr>", "Diagnostics" },
        k = { "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>", "Live Grep" },
        l = { "<cmd>Telescope file_browser<cr>", "File Browser" },
        m = { "<cmd>Telescope marks<cr>", "Marks" },
        n = { "<cmd>Telescope command_history<cr>", "Command History" },
        o = { "<cmd>Telescope projects<cr>", "Recent Projects" },
        p = { "<cmd>Telescope jumplist<cr>", "Jumplist" },
        r = { "<cmd>lua require'telescope'.extensions.project.project{} <cr>", "Recent Project History" },
        s = { "<cmd>Telescope search_history<cr>", "Search History" },
        t = { "<cmd>Telescope git_status<cr>", "Git status" },
        u = { "<cmd>Telescope dir find_files<cr>", "Dir Find Files" },
        y = { "<cmd>Telescope session-lens<cr>", "Session" },
    },
}
require("which-key").register(keymap, normal_opts)
