local status_ok, noice = pcall(require, "noice")
if not status_ok then
        return
end

noice.setup()
require("telescope").load_extension("noice")
