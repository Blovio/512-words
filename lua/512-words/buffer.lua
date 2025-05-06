local config = require("512-words.config")

---@class Buffer512
local M = {
	buf = nil,
	floating_calendar_buf = nil,
	floating_calendar_win = nil,
	floating_words_buf = nil,
	floating_words_win = nil,
	init = false,
	curr_dir = nil,
}

---@param buf number
local function split_above(buf)
	vim.api.nvim_command("split")
	vim.api.nvim_command("wincmd K")
	vim.api.nvim_set_current_buf(buf)
end

local function get_stars_arr()
	local current_date = os.date("*t")
	local year, month = current_date.year, current_date.month

	local firstDayOfMonth = os.date("*t", os.time({ year = year, month = month, day = 1 }))
	local lastDayOfMonth = os.date("*t", os.time({ year = year, month = month + 1, day = 0 }))

	local offset = firstDayOfMonth.wday - 1
	local dir = vim.fn.expand(M.curr_dir)
	local files = vim.fn.readdir(dir)
	local starArr = {}

	-- Prefill so calendar is accurate for the month
	for _ = 1, offset do
		table.insert(starArr, "⬜ ")
	end
	for _ = 1, lastDayOfMonth.day do
		table.insert(starArr, "🟧 ")
	end

	for _, file in ipairs(files) do
		local filepath = M.curr_dir .. "/" .. file
		local lines = vim.fn.readfile(filepath)
		local text = table.concat(lines, " ")
		local word_count = 0
		for _ in text:gmatch("%S+") do
			word_count = word_count + 1
		end

		local _, _, _, m, d = string.find(file, "(%d+)-(%d+)-(%d+)")
		local monthNum = tonumber(m)
		local dayNum = tonumber(d)
		if firstDayOfMonth.month == monthNum and word_count >= config.options.words then
			starArr[dayNum + offset] = "⭐ "
		end
	end
	return starArr, offset
end

local function update_floating_window()
	if not M.floating_calendar_buf or not M.floating_calendar_win then
		return
	end
	-- Ignore the first 2 lines and count the rest
	local lines = vim.api.nvim_buf_get_lines(M.buf, 2, -1, false)
	local text = table.concat(lines, " ")
	local current_date = os.date("*t")
	local word_count = 0
	for _ in text:gmatch("%S+") do
		word_count = word_count + 1
	end

	-- Check if user has passed words threshold
	local arr, offset = get_stars_arr()
	arr[current_date.day + offset] = (word_count >= config.options.words) and "⭐ " or "🟩 "

	vim.api.nvim_buf_set_lines(M.floating_calendar_buf, 0, -1, false, {
		"S  M  T  W  Th F Sat",
		table.concat(arr, ""),
	})
	vim.api.nvim_buf_set_lines(M.floating_words_buf, 0, -1, false, {
		" Word Count: " .. word_count,
	})
end

local function ensure_floating_windows()
	local words_width = 17
	local words_height = 1
	local calendar_width = 21
	local calendar_height = 7

	if not M.floating_calendar_buf then
		M.floating_calendar_buf = vim.api.nvim_create_buf(false, true)
	end
	if not M.floating_words_buf then
		M.floating_words_buf = vim.api.nvim_create_buf(false, true)
	end
	if not M.floating_words_win or not vim.api.nvim_win_is_valid(M.floating_words_win) then
		M.floating_words_win = vim.api.nvim_open_win(M.floating_words_buf, false, {
			relative = "editor",
			width = words_width,
			height = words_height,
			row = 0,
			col = vim.o.columns - words_width - 2,
			style = "minimal",
			noautocmd = true,
			focusable = false,
		})
	end
	if not M.floating_calendar_win or not vim.api.nvim_win_is_valid(M.floating_calendar_win) then
		M.floating_calendar_win = vim.api.nvim_open_win(M.floating_calendar_buf, false, {
			relative = "editor",
			width = calendar_width,
			height = calendar_height,
			row = vim.o.lines - calendar_height - 2,
			col = vim.o.columns - calendar_width - 2,
			style = "minimal",
			border = "rounded",
			noautocmd = true,
			focusable = false,
		})
	end
	update_floating_window()
end

---@param opts Options512
local function set_local_opts(opts)
	for k, v in pairs(opts.buffer or {}) do
		vim.api.nvim_set_option_value(k, v, { buf = M.buf })
	end
	for k, v in pairs(opts.window or {}) do
		vim.api.nvim_set_option_value(k, v, { win = 0 })
	end
end

local function close_floating_windows()
	if vim.api.nvim_win_is_valid(M.floating_calendar_win) then
		vim.api.nvim_win_close(M.floating_calendar_win, true)
	end
	if vim.api.nvim_win_is_valid(M.floating_words_win) then
		vim.api.nvim_win_close(M.floating_words_win, true)
	end
end

local function toggle_floating_window()
	if vim.api.nvim_win_is_valid(M.floating_calendar_win) then
		vim.api.nvim_win_close(M.floating_calendar_win, true)
	else
		ensure_floating_windows()
	end
end

---@param opts Options512
local function init_buffer(opts)
	set_local_opts(opts)
	vim.keymap.set("n", opts.floating_calendar_keybind, toggle_floating_window, { buffer = M.buf })
	ensure_floating_windows()

	-- Apply autocommands to buffer
	local autocommands = {
		{ events = { "TextChanged", "TextChangedI" }, callback = update_floating_window },
		{ events = "BufEnter",                        callback = ensure_floating_windows },
		{ events = "BufLeave",                        callback = close_floating_windows },
		{
			events = "InsertLeave",
			callback = function()
				if vim.bo.modified then
					-- Silent write... Holy write. All is saved. All is fine.
					vim.cmd("silent write")
				end
			end,
		},
	}

	for _, cmd in ipairs(autocommands) do
		vim.api.nvim_create_autocmd(cmd.events, { buffer = M.buf, callback = cmd.callback })
	end

	M.init = true
end

---@param filepath string
---@param opts Options512
local function reopen(filepath, opts)
	if opts.split then
		vim.api.nvim_command("split")
		vim.api.nvim_command("wincmd K")
	end
	vim.api.nvim_command("edit " .. filepath)
	M.buf = vim.api.nvim_get_current_buf()

	if not M.init then
		init_buffer(opts)
	end
end

---@param opts Options512
---@param filename string
local function create(filename, opts)
	local lines
	if opts.date_prefix == "" then
		lines = { os.date("%A %B %d, %Y"), "", "" }
	else
		lines = { string.format("%s %s", opts.date_prefix, os.date("%A %B %d, %Y")), "", "" }
	end
	local buf = vim.api.nvim_create_buf(true, false)

	M.buf = buf

	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_name(M.buf, filename)

	if opts.split then
		split_above(M.buf)
	else
		vim.api.nvim_set_current_buf(M.buf)
	end

	if not M.init then
		init_buffer(opts)
	end
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	local ft = vim.filetype.match({ filename = filename })
	vim.api.nvim_set_option_value("filetype", ft, { buf = M.buf })
end

function M.open()
	local today = os.date("%Y-%m-%d")
	local yearMonth = os.date("%Y-%m")
	local storage_dir = vim.fn.expand(config.options.storage_directory)
	local dir_yearMonth = storage_dir .. "/512-words/" .. tostring(yearMonth)
	local file_ext = config.options.file_extension

	if vim.fn.isdirectory(dir_yearMonth) == 0 then
		vim.fn.mkdir(dir_yearMonth, "p")
	end

	M.curr_dir = dir_yearMonth

	local filepath = dir_yearMonth .. "/" .. today .. file_ext
	if vim.fn.filereadable(filepath) == 1 then
		reopen(filepath, config.options)
	else
		create(filepath, config.options)
	end
end

return M
