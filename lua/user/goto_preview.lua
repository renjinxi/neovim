local status_ok, goto_preview = pcall(require, "goto-preview")
if not status_ok then
        return
end

local post_open_hook = function(_, win)
        vim.api.nvim_win_set_option(win, "winhighlight", "Normal:")
end

goto_preview.setup({
        post_open_hook = post_open_hook,
})

local w_status_ok, which_key = pcall(require, "which-key")

if not w_status_ok then
        return
end

local M = {}

function M.setup()
        local keymap = {
                j = {
                        name = "goto_preview",
                        d = { "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", "Go to definition" },
                        t = {
                                "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
                                "Go totype definition",
                        },
                        i = { "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", "Go to implemention" },
                        c = { "<cmd>lua require('goto-preview').close_all_win()<CR>", "close all win" },
                        r = { "<cmd>lua require('goto-preview').goto_preview_references()<CR>", "Go to references" },
                },
        }

        which_key.register(keymap, {
                mode = "n",
                prefix = "<leader>",
                buffer = nil,
                silent = true,
                noremap = true,
                nowait = false,
        })
end

M.setup()
