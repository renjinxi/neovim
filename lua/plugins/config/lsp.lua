-- ================================
-- LSP 配置 (2025年 Neovim 0.11+ 现代化版本)
-- ================================

-- 诊断配置
vim.diagnostic.config({
	virtual_text = false, -- 禁用虚拟文本显示
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚",
			[vim.diagnostic.severity.WARN] = "󰀪",
			[vim.diagnostic.severity.HINT] = "󰌶", 
			[vim.diagnostic.severity.INFO] = "●",
		},
	},
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	float = {
		focusable = false,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
	},
})

-- LSP 服务器配置 (使用新的 vim.lsp.config API)
vim.lsp.config('lua_ls', {
	cmd = { 'lua-language-server' },
	root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
	filetypes = { 'lua' },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = { "vim", "use" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					[vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
				},
				maxPreload = 100000,
				preloadFileSize = 10000,
			},
			telemetry = {
				enable = false,
			},
			completion = {
				callSnippet = "Replace",
			},
		},
	},
})

vim.lsp.config('clangd', {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
	},
	root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
	filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
	init_options = {
		usePlaceholders = true,
		completeUnimported = true,
		clangdFileStatus = true,
	},
	capabilities = {
		offsetEncoding = { "utf-16" },
	},
})

vim.lsp.config('pyright', {
	cmd = { 'pyright-langserver', '--stdio' },
	root_markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pytest.ini' },
	filetypes = { 'python' },
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "workspace",
			},
		},
	},
})

vim.lsp.config('ruff', {
	cmd = { 'ruff', 'server', '--preview' },
	root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml' },
	filetypes = { 'python' },
	init_options = {
		settings = {
			args = {},
		},
	},
})

vim.lsp.config('html', {
	cmd = { 'vscode-html-language-server', '--stdio' },
	root_markers = { 'package.json', '.git' },
	filetypes = { 'html' },
	settings = {
		html = {
			format = {
				templating = true,
				wrapLineLength = 120,
				wrapAttributes = "auto",
			},
			hover = {
				documentation = true,
				references = true,
			},
		},
	},
})

vim.lsp.config('cssls', {
	cmd = { 'vscode-css-language-server', '--stdio' },
	root_markers = { 'package.json', '.git' },
	filetypes = { 'css', 'scss', 'less' },
	settings = {
		css = {
			validate = true,
			lint = {
				unknownAtRules = "ignore",
			},
		},
		scss = {
			validate = true,
			lint = {
				unknownAtRules = "ignore",
			},
		},
		less = {
			validate = true,
			lint = {
				unknownAtRules = "ignore",
			},
		},
	},
})

vim.lsp.config('ts_ls', {
	cmd = { 'typescript-language-server', '--stdio' },
	root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' },
	filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
	init_options = {
		preferences = {
			disableSuggestions = false,
		},
	},
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "literal",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = false,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
})

vim.lsp.config('gopls', {
	cmd = { 'gopls' },
	root_markers = { 'go.work', 'go.mod', '.git' },
	filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
			gofumpt = true,
			codelenses = {
				gc_details = false,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
		},
	},
})

vim.lsp.config('nginx_language_server', {
	cmd = { 'nginx-language-server' },
	root_markers = { 'nginx.conf', '.git' },
	filetypes = { 'nginx' },
	settings = {},
})

-- Kotlin 语言服务器配置
vim.lsp.config('kotlin_language_server', {
	cmd = { 'kotlin-language-server' },
	root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', '.git' },
	filetypes = { 'kotlin' },
	init_options = {
		storagePath = vim.fn.stdpath("data") .. "/kotlin",
	},
	settings = {
		kotlin = {
			compiler = {
				jvm = {
					target = "11",
				},
			},
			linting = {
				debounceTime = 250,
			},
		},
	},
})

-- JSON 语言服务器配置 (使用 schemastore)
local schemastore_available, schemastore = pcall(require, "schemastore")
if schemastore_available then
	vim.lsp.config('jsonls', {
		cmd = { 'vscode-json-language-server', '--stdio' },
		root_markers = { 'package.json', '.git' },
		filetypes = { 'json', 'jsonc' },
		settings = {
			json = {
				schemas = schemastore.json.schemas(),
				validate = { enable = true },
			},
		},
	})
else
	vim.lsp.config('jsonls', {
		cmd = { 'vscode-json-language-server', '--stdio' },
		root_markers = { 'package.json', '.git' },
		filetypes = { 'json', 'jsonc' },
		settings = {
			json = {
				validate = { enable = true },
			},
		},
	})
end

-- 文档高亮设置
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.server_capabilities.documentHighlightProvider then
			vim.api.nvim_create_augroup("lsp_document_highlight", {
				clear = false,
			})
			vim.api.nvim_clear_autocmds({
				buffer = args.buf,
				group = "lsp_document_highlight",
			})
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = "lsp_document_highlight",
				buffer = args.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved" }, {
				group = "lsp_document_highlight",
				buffer = args.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
		
		-- 服务器连接信息 (静默模式，不显示提示)
		-- if client then
		-- 	print(string.format("LSP [%s] attached to buffer %d", client.name, args.buf))
		-- end
	end,
})

-- 注意：由于 mason-lspconfig.nvim 配置了 automatic_enable = true，
-- 已安装的服务器会自动启用，无需手动调用 vim.lsp.enable()
-- 这些 vim.lsp.config() 配置会在服务器启动时自动应用

-- Java 语言服务器使用特殊的 nvim-jdtls 插件配置
-- 配置会在打开 Java/Kotlin 文件时自动加载（见 jdtls.lua 中的 autocmd）