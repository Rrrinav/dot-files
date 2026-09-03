-- config/health.lua - :checkhealth for this config
local M = {}

function M.check()
  vim.health.start("rinav/nvim")

  -- Neovim version
  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim >= 0.12")
  else
    vim.health.warn("Neovim < 0.12 - vim.pack requires 0.12+")
  end

  -- Palette
  local ok, palette = pcall(require, "config.palette")
  if ok and palette.themes and palette.themes.kanagawa_dragon2 then
    vim.health.ok("palette: " .. tostring(vim.tbl_count(palette.themes)) .. " themes loaded")
  else
    vim.health.error("palette failed to load")
  end

  -- Core modules
  for _, mod in ipairs({ "config.options", "config.diagnostics", "config.keymaps", "config.autocmds" }) do
    if pcall(require, mod) then
      vim.health.ok(mod .. " loads")
    else
      vim.health.error(mod .. " failed")
    end
  end

  -- Plugins load (via load_configs safe loader)
  for _, mod in ipairs({ "plugins.mini", "plugins.snacks", "plugins.blink", "plugins.treesitter" }) do
    local ok2 = pcall(require, mod)
    if not ok2 then vim.health.warn(mod .. " not loaded (may be lazy)") end
  end

  -- External deps
  if vim.fn.executable("wl-copy") == 1 or vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1 then
    vim.health.ok("clipboard tool found (wl-copy/xclip/xsel)")
  else
    vim.health.warn("no clipboard tool (wl-copy/xclip/xsel) - tmux yank will fail outside tmux")
  end

  if vim.fn.executable("rg") == 1 then
    vim.health.ok("ripgrep (rg) found - telescope live_grep works")
  else
    vim.health.warn("rg not found")
  end
end

return M
