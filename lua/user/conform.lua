local status_ok, _ = pcall(require, "conform")
if not status_ok then
    return
end
require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        -- Conform will run multiple formatters sequentially
        python = { "ruff" },
        -- Use a sub-list to run only the first available formatter
        --javascript = { { "prettierd", "prettier" } },
    },
})
