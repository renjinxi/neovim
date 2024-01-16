local status_ok, chatgpt = pcall(require, "chatgpt")
if not status_ok then
        return
end

chatgpt.setup()

--chatpgt.setup({
--api_key_cmd = "/bin/cat /Users/renjinxi/tmp/password/chatpgt.password"
--})
