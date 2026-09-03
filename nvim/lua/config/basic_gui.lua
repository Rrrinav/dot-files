-- config/basic_gui.lua - backward compat shim
-- Delegates to config.options and config.diagnostics (split for manageability).
-- Keep this file so existing init.lua:4 `require("config.basic_gui").setup()` still works.

local M = {}

function M.setup()
  require("config.options").setup()
  require("config.diagnostics").setup()
end

return M
