require("telescope").load_extension("file_browser")
require("telescope").load_extension("projects")
require'telescope'.load_extension('project')
require("telescope").load_extension("dir")

local project_actions = require("telescope._extensions.project.actions")
require('telescope').setup({
  extensions = {
    project = {
      base_dirs = {
        "/Users/renjinxi/.pyenv/versions/3.12.0",
      },
      hidden_files = true, -- default: false
      theme = "dropdown",
      order_by = "asc",
      search_by = "title",
      sync_with_nvim_tree = true, -- default false
      -- default for on_project_selected = find project files
      on_project_selected = function(prompt_bufnr)
        -- Do anything you want in here. For example:
        project_actions.change_working_directory(prompt_bufnr, false)
        require("harpoon.ui").nav_file(1)
      end
    }
  }
})
