local w_status_ok, which_key = pcall(require, "which-key")

if not w_status_ok then
    return
end

local keymap = {
    j = {
        name = "goto_preview",
        c = { "<cmd>lua require('goto-preview').close_all_win()<CR>", "close all win" },
        d = { "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", "Go to definition" },
        i = { "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", "Go to implemention" },
        r = { "<cmd>lua require('goto-preview').goto_preview_references()<CR>", "Go to references" },
        t = { "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", "Go totype definition", },
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

