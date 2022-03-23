require "user.theme"
require "user.plugins"
require "user.which_key"
require "user.auto_commands"
require "user.globals"
require "user.options"
require "user.keymaps"
require "user.treesitter"
require "user.cmp"
require "user.nvim-ufo"
require "user.lsp"
require "user.dap"
require "user.nvim-tree"
require "user.lualine"
require "user.neogen"
require "user.formatter"
require "user.autosave"
require "user.toggleterm"
require "user.trouble"
require "user.goto_preview"
require "user.bqf"
require "user.telescope"
require "user.indent_blankline"


require("symbols-outline").setup({
        symbols = {
                File = { icon = '󰈔', hl = '@text.uri' },
                Module = { icon = '󰆧', hl = '@namespace' },
                Namespace = { icon = '󰅪', hl = '@namespace' },
                Package = { icon = "", hl = "@namespace" },
                Class = { icon = "𝓒", hl = "@type" },
                Method = { icon = "ƒ", hl = "@method" },
                Property = { icon = "", hl = "@method" },
                Field = { icon = '󰆨', hl = '@field' },
                Constructor = { icon = "", hl = "@constructor" },
                Enum = { icon = "ℰ", hl = "@type" },
                Interface = { icon = "ﰮ", hl = "@type" },
                Function = { icon = "", hl = "@function" },
                Variable = { icon = "", hl = "@constant" },
                Constant = { icon = "", hl = "@constant" },
                String = { icon = "𝓐", hl = "@string" },
                Number = { icon = "#", hl = "@number" },
                Boolean = { icon = "⊨", hl = "@boolean" },
                Array = { icon = '󰅪', hl = '@constant' },
                Object = { icon = "⦿", hl = "@type" },
                Key = { icon = "🔐", hl = "@type" },
                Null = { icon = "NULL", hl = "@type" },
                EnumMember = { icon = "", hl = "@field" },
                Struct = { icon = "𝓢", hl = "@type" },
                Event = { icon = "", hl = "@type" },
                Operator = { icon = "", hl = "@operator" },
                TypeParameter = { icon = "𝙏", hl = "@parameter" },
                Component = { icon = '󰅴', hl = '@function' },
                Fragment = { icon = '󰅴', hl = '@constant' },
        }
})
