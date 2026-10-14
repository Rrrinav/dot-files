-- lua/config/palette.lua - now a loader for themes/* (split for manageability)
-- Add a new theme by editing lua/config/themes/*.lua or creating a new file there.

local M = {}

M.themes = {}

-- Merge theme families
for _, group in ipairs({ "neutral", "warm", "cool", "green", "purple", "popular" }) do
  local ok, tbl = pcall(require, "config.themes." .. group)
  if ok and type(tbl) == "table" then
    for name, colors in pairs(tbl) do
      M.themes[name] = colors
    end
  else
    vim.notify("[palette] failed to load themes/" .. group .. ": " .. tostring(tbl), vim.log.levels.WARN)
  end
end

-- Active State
M.colors = vim.deepcopy(M.themes.espresso)

-- Static Elements
M.static = {
  fg_bright   = "#fafafa",
  cursor_line = "#2f2f2f",
  cursor_bg   = "#fff1da",
  cursor_fg   = "#fff1da",
  visual      = "#2a2f2f",
  comment     = "#6c6c9c",
  inlay_bg    = "#282828",
  inlay_fg    = "#4fa8a8",
  whitespace  = "#4444aa",
  special_key = "#88a888",
  non_text    = "#666666",
  msg_area    = "#b1b1ff",
}

return M
