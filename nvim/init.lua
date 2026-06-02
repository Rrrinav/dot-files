vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.packpath:append(vim.fn.stdpath("data") .. "/site")
require("packs")

require("load_configs")

require("config.basic_gui").setup()
require("config.user_commands").setup()
require("config.misc")
require("config.filetypes")

require("config.keymaps")
require("config.autocmds")

vim.cmd.colorscheme("nord")

require("statusline").setup()
require("tabline").setup()
require("custom.swap_words").setup()
require("custom.compile_mode").setup()
require("custom.frecency_tab.init").setup({
  keymaps = {
    open         = "<leader>ts",
    open_reverse = "<leader>tS",
  },
  persist_path = vim.fn.stdpath("data") .. "/frecency_tab.dat",
})

require("config.set-highlights").setup()

vim.notify("Hello Rinav", vim.log.levels.INFO, {
  title = "Sukhoi  "
})
