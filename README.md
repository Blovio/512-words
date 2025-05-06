## 512-words
A plugin to help you journal everyday!

## Description
512-words is a plugin that automatically opens a buffer and starts counting the number of words you
are typing. It also displays a calendar for the journals where you have exceeded 512 words. The
number of words needed to achieve a star can be adjusted to whatever number you see fit. You can
close the calendar in normal mode by pressing `g.`. 

## Motivation
This plugin was inspired by the website [750-words](https://750words.com). I built this because I
wanted a local method for journaling, and I find it much nicer to do my journaling in Neovim. For me
it's more comfortable. 

## Usage
For `Packer`:
```
use { "Blovio/512-words" }
```

For `Lazy.nvim`:
```
{ "Blovio/512-words" }
```

## Basic Usage

Use the command `:Words`

Optionally you can make a keybind to open this plugin by doing:

```lua
vim.keymap.set("n", "gW", function()
    require("512-words").open()
end)
```

## Default Settings
```lua
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
	storage_directory = tostring(vim.fn.stdpath("data")), -- Where all your files are saved, if you change the default "~" will be expanded for you.
	file_extension = ".txt", -- allow configuration
	date_prefix = "", -- useful to add header tag to date for markdown

	-- NOTE: Do not alter the folder/file naming structure in the saved directory. The files are read to determine stars.
}
```
