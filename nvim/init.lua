vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.basic_gui").setup()
vim.opt.packpath:append(vim.fn.stdpath("data") .. "/site")
local pack_opt = vim.fn.stdpath("data") .. "/site/pack/core/opt"
local handle = vim.uv.fs_scandir(pack_opt)
if handle then
  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then break end
    if type == "directory" then
      vim.opt.runtimepath:append(pack_opt .. "/" .. name)
    end
  end
end

require("packs")
require("load_configs")

-- require("load_configs")

require("config.user_commands").setup()
require("config.misc")
require("config.filetypes")

require("config.keymaps")
require("config.autocmds")

vim.cmd.colorscheme("kanagawa-dragon")

require("statusline").setup()
require("tabline").setup()
require("custom.swap_words").setup()
require("custom.compile_mode").setup()
require("custom.frecency_tab.init").setup({
  keymaps = {
    open         = "<leader>bs",
    open_reverse = "<leader>bS",
  },
  persist_path = vim.fn.stdpath("data") .. "/frecency_tab.dat",
})

require("config.set-highlights").setup()

vim.notify("Hello Rinav", vim.log.levels.INFO, {
  title = "MIG-29 󱜿 "
})
