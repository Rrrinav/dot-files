vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Safe require helper: one failure doesn't abort startup
local function safe_require(mod, setup_fn)
  local ok, m = pcall(require, mod)
  if not ok then
    vim.notify(("[init] failed to load %s: %s"):format(mod, m), vim.log.levels.ERROR)
    return nil
  end
  if setup_fn and m and m[setup_fn] then
    local ok2, err = pcall(m[setup_fn], m)
    if not ok2 then vim.notify(("[init] %s:%s failed: %s"):format(mod, setup_fn, err), vim.log.levels.ERROR) end
  end
  return m
end

safe_require("config.basic_gui", "setup")

safe_require("packs")
safe_require("load_configs")

local uc = safe_require("config.user_commands")
if uc then
  pcall(uc.setup)
end

safe_require("config.misc")
safe_require("config.filetypes")

safe_require("config.keymaps")
safe_require("config.autocmds")

vim.cmd.colorscheme("onedark")

safe_require("statusline", "setup")
safe_require("tabline", "setup")
safe_require("custom.swap_words", "setup")
safe_require("custom.compile_mode", "setup")
safe_require("custom.outline", "setup")

do
  local ok, mod = pcall(require, "custom.frecency_tab.init")
  if ok then
    pcall(mod.setup, {
      keymaps = {
        open         = "<leader>bs",
        open_reverse = "<leader>bS",
      },
      persist_path = vim.fn.stdpath("data") .. "/frecency_tab.dat",
    })
  else
    vim.notify("[init] frecency_tab failed: " .. tostring(mod), vim.log.levels.ERROR)
  end
end

do
  local ok, mod = pcall(require, "config.set-highlights")
  if ok then pcall(mod.setup) end
end

vim.notify("Hello Rinav", vim.log.levels.INFO, {
  title = "MIG-29 󱜿 "
})
