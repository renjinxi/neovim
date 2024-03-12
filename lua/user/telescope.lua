require("telescope").load_extension("file_browser")
--require("telescope").load_extension("projects")
--require 'telescope'.load_extension('project')
--require("telescope").load_extension("dir")
local lga_actions = require("telescope-live-grep-args.actions")

--local project_actions = require("telescope._extensions.project.actions")
require('telescope').setup({
    defaults = {
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
        }
    },
    extensions = {
        --project = {
            --base_dirs = {
                --"/Users/renjinxi/.pyenv/versions/3.12.0",
            --},
            --hidden_files = true,             -- default: false
            --theme = "dropdown",
            --order_by = "asc",
            --search_by = "title",
            --sync_with_nvim_tree = true,             -- default false
            ---- default for on_project_selected = find project files
            --on_project_selected = function(prompt_bufnr)
                ---- Do anything you want in here. For example:
                --project_actions.change_working_directory(prompt_bufnr, false)
                --require("harpoon.ui").nav_file(1)
            --end
        --},

        live_grep_args = {
            auto_quoting = true,             -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = {                     -- extend mappings
                i = {
                    ["<C-k>"] = lga_actions.quote_prompt(),
                    ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                },
            },
            -- ... also accepts theme settings, for example:
            -- theme = "dropdown", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
        }
    }
})
