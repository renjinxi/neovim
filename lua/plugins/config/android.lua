-- ================================
-- Android 开发工具集成
-- 集成 ADB 命令和 Gradle 构建
-- ================================

local M = {}

-- 在水平分割终端中运行命令（原生实现）
local function run_in_terminal(cmd)
	vim.cmd("botright 15split")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(0, buf)
	vim.fn.termopen(cmd)
	vim.cmd("startinsert")
end

-- ADB 命令定义
M.adb_commands = {
	-- 设备管理
	{
		name = "列出连接的设备",
		cmd = "adb devices -l",
		desc = "List all connected devices",
	},
	{
		name = "获取设备信息",
		cmd = "adb shell getprop ro.build.version.release && adb shell getprop ro.product.model",
		desc = "Get Android version and model",
	},
	{
		name = "重启设备",
		cmd = "adb reboot",
		desc = "Reboot device",
		confirm = true,
	},

	-- 日志查看
	{
		name = "清空日志",
		cmd = "adb logcat -c",
		desc = "Clear logcat",
	},
	{
		name = "查看错误日志",
		cmd = "adb logcat *:E",
		desc = "Show error logs only",
	},
	{
		name = "查看所有日志",
		cmd = "adb logcat",
		desc = "Show all logs",
	},
	{
		name = "查看崩溃日志",
		cmd = "adb logcat -b crash",
		desc = "Show crash logs",
	},

	-- 包管理
	{
		name = "列出所有包",
		cmd = "adb shell pm list packages",
		desc = "List all installed packages",
	},
	{
		name = "列出第三方包",
		cmd = "adb shell pm list packages -3",
		desc = "List third-party packages",
	},
	{
		name = "清除应用数据",
		cmd = function()
			vim.ui.input({ prompt = "Package name: " }, function(package)
				if package and package ~= "" then
					run_in_terminal("adb shell pm clear " .. package)
				end
			end)
		end,
		desc = "Clear app data",
	},
	{
		name = "卸载应用",
		cmd = function()
			vim.ui.input({ prompt = "Package name: " }, function(package)
				if package and package ~= "" then
					run_in_terminal("adb uninstall " .. package)
				end
			end)
		end,
		desc = "Uninstall app",
	},

	-- 文件操作
	{
		name = "推送文件到设备",
		cmd = function()
			vim.ui.input({ prompt = "Local file: " }, function(local_file)
				if local_file and local_file ~= "" then
					vim.ui.input({ prompt = "Device path: ", default = "/sdcard/" }, function(device_path)
						if device_path and device_path ~= "" then
							run_in_terminal("adb push " .. local_file .. " " .. device_path)
						end
					end)
				end
			end)
		end,
		desc = "Push file to device",
	},
	{
		name = "从设备拉取文件",
		cmd = function()
			vim.ui.input({ prompt = "Device path: " }, function(device_path)
				if device_path and device_path ~= "" then
					vim.ui.input({ prompt = "Local path: ", default = "./" }, function(local_path)
						if local_path and local_path ~= "" then
							run_in_terminal("adb pull " .. device_path .. " " .. local_path)
						end
					end)
				end
			end)
		end,
		desc = "Pull file from device",
	},
	{
		name = "查看应用数据目录",
		cmd = "adb shell ls /data/data",
		desc = "List app data directories",
	},

	-- 应用管理
	{
		name = "安装 APK",
		cmd = function()
			vim.ui.input({ prompt = "APK path: " }, function(apk_path)
				if apk_path and apk_path ~= "" then
					run_in_terminal("adb install -r " .. apk_path)
				end
			end)
		end,
		desc = "Install APK",
	},
	{
		name = "启动应用",
		cmd = function()
			vim.ui.input({ prompt = "Package/Activity (e.g., com.example/.MainActivity): " }, function(activity)
				if activity and activity ~= "" then
					run_in_terminal("adb shell am start -n " .. activity)
				end
			end)
		end,
		desc = "Start app activity",
	},
	{
		name = "停止应用",
		cmd = function()
			vim.ui.input({ prompt = "Package name: " }, function(package)
				if package and package ~= "" then
					run_in_terminal("adb shell am force-stop " .. package)
				end
			end)
		end,
		desc = "Force stop app",
	},
	{
		name = "查看当前运行的Activity",
		cmd = "adb shell dumpsys window | grep mCurrentFocus",
		desc = "Show current activity",
	},

	-- 屏幕截图和录屏
	{
		name = "截图并保存",
		cmd = function()
			local timestamp = os.date("%Y%m%d_%H%M%S")
			local filename = "screenshot_" .. timestamp .. ".png"
			run_in_terminal(
				string.format(
					"adb shell screencap -p /sdcard/%s && adb pull /sdcard/%s ./ && adb shell rm /sdcard/%s",
					filename,
					filename,
					filename
				)
			)
		end,
		desc = "Take screenshot and pull to current dir",
	},

	-- 设备控制
	{
		name = "返回桌面",
		cmd = "adb shell input keyevent KEYCODE_HOME",
		desc = "Press home button",
	},
	{
		name = "返回上一页",
		cmd = "adb shell input keyevent KEYCODE_BACK",
		desc = "Press back button",
	},
	{
		name = "查看内存使用",
		cmd = function()
			vim.ui.input({ prompt = "Package name (or leave empty for all): " }, function(package)
				if package and package ~= "" then
					run_in_terminal("adb shell dumpsys meminfo " .. package)
				else
					run_in_terminal("adb shell dumpsys meminfo")
				end
			end)
		end,
		desc = "Show memory usage",
	},
}

-- Gradle 快捷命令
M.gradle_commands = {
	{
		name = "Clean 项目",
		cmd = "./gradlew clean",
		desc = "Clean build artifacts",
	},
	{
		name = "编译 Debug 版本",
		cmd = "./gradlew assembleDebug",
		desc = "Build debug APK",
	},
	{
		name = "编译 Release 版本",
		cmd = "./gradlew assembleRelease",
		desc = "Build release APK",
	},
	{
		name = "运行单元测试",
		cmd = "./gradlew test",
		desc = "Run unit tests",
	},
	{
		name = "安装到设备",
		cmd = "./gradlew installDebug",
		desc = "Install debug APK to device",
	},
	{
		name = "完整构建",
		cmd = "./gradlew build",
		desc = "Full build",
	},
}

-- 使用 Telescope 选择并运行 ADB 命令
function M.adb_picker()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "ADB Commands",
			finder = finders.new_table({
				results = M.adb_commands,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name .. " " .. entry.desc,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						local cmd = selection.value.cmd

						-- 如果需要确认
						if selection.value.confirm then
							vim.ui.select({ "Yes", "No" }, {
								prompt = "确认执行: " .. selection.value.name .. "?",
							}, function(choice)
								if choice == "Yes" then
									if type(cmd) == "function" then
										cmd()
									else
										run_in_terminal(cmd)
									end
								end
							end)
						else
							if type(cmd) == "function" then
								cmd()
							else
								run_in_terminal(cmd)
							end
						end
					end
				end)
				return true
			end,
		})
		:find()
end

-- 使用 Telescope 选择并运行 Gradle 命令
function M.gradle_picker()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Gradle Tasks",
			finder = finders.new_table({
				results = M.gradle_commands,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name .. " " .. entry.desc,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						run_in_terminal(selection.value.cmd)
					end
				end)
				return true
			end,
		})
		:find()
end

-- 快速查看错误日志
function M.show_error_log()
	run_in_terminal("adb logcat *:E")
end

return M
