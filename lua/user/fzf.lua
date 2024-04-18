local fzf_lua = require('fzf-lua')

function ChangeDirectory(opts)
    opts = opts or {}
    opts.prompt = "Directories> "
    opts.fn_transform = function(x)
        return fzf_lua.utils.ansi_codes.magenta(x)
    end
    opts.actions = {
        ['default'] = function(selected)
            vim.cmd("cd " .. selected[1])
        end
    }
    fzf_lua.fzf_exec("fd --type d", opts)
end

-- 注册Neovim命令
vim.api.nvim_create_user_command('Fcd', ChangeDirectory, {})
