return {
	strategies = {
		chat = {
			adapter = "claude_code",
			keymaps = {
				send = { modes = { n = "<cr>", i = "<C-s>" } },
				close = { modes = { n = "q", i = "<C-c>" } },
			},
		},
		inline = {
			adapter = "claude_code",
		},
	},
	opts = {
		log_level = "ERROR",
	},
}
