local M = {}

---@class Options512
local defaults = {
	-- uncomment any of the options below, or add other vim.bo / vim.wo options you want to apply
	buffer = {
		textwidth = 0, -- auto-wrapping at a fixed width (inserts \n newlines)
		formatoptions = "qt", -- allow auto formatting with gq (inserts \n newlines), auto wrap if textwidth is > 0
	},
	window = {
		list = false, -- Disable whitespace characters
		relativenumber = false, -- Disable relative numbers
		cursorcolumn = false, -- Disable cursor column
		signcolumn = "no", -- signcolumn
		number = false, -- number column
		wrap = true, -- Enable soft wrapping
		linebreak = true, -- Break lines at word boundaries
		showbreak = "↪ ", -- Indicator for wrapped lines
		spell = true, -- Spellcheck
	},
	floating_calendar_keybind = "g.", -- Keybind to toggle calendar in normal mode.
	split = true, -- If true, will create the journal window as a split, false creates a new buffer window
	words = 0x200, -- (0x200 == 512) Set the number of words required to get a star ⭐
	-- NOTE: Do not alter the folder/file naming structure in the saved directory. The files are read to determine stars.
	storage_directory = tostring(vim.fn.stdpath("data")), -- Where all your files are saved, if you change the default "~" will be expanded for you.
	file_extension = ".txt", -- allow configuration
	date_prefix = "", -- allows for a markdown header marker
}

---@type Options512
M.options = nil

---@param options table?
function M.setup(options)
	-- "force" overrides defaults with options
	M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return setmetatable(M, {
	-- __index is a metatable method that gets called when key doesn't exist on table
	__index = function(_, k)
		if k == "options" then
			M.setup()
		end
		return rawget(M, k)
	end,
})
