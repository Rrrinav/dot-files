-- frecency_tab/init.lua
-- Public API + setup

local M = {}

local frecency = require("custom.frecency_tab.frecency")
local ui       = require("custom.frecency_tab.ui")

local defaults = {
  keymaps = {
    open         = "<leader>ts",
    open_reverse = "<leader>tS",
  },
  persist_path = vim.fn.stdpath("data") .. "/frecency_tab.dat",
}

-- Define highlight groups by linking to standard Neovim groups.
-- Users can override any of these after setup() with :hi or vim.api.nvim_set_hl.
local function define_highlights()
  local function hi(name, opts)
    -- Only set if not already defined by the user (default = true means "set fresh")
    vim.api.nvim_set_hl(0, name, opts)
  end

  -- Window background — inherits the normal float look
  hi("FrecencyNormal",      { link = "NormalFloat" })
  -- Border — inherits float border
  hi("FrecencyBorder",      { link = "FloatBorder" })
  -- Line numbers in the gutter
  hi("FrecencyLineNr",      { link = "LineNr" })
  -- Unselected rows
  hi("FrecencyItem",        { link = "NormalFloat" })
  -- Selected row
  hi("FrecencySelected",    { link = "CursorLine" })
  -- Modified marker on unselected row
  hi("FrecencyModified",    { link = "DiagnosticWarn" })
  -- Modified marker on selected row
  hi("FrecencyModifiedSel", { link = "DiagnosticWarn" })
end

---Setup the plugin.
---@param opts table|nil
function M.setup(opts)
  local cfg = vim.tbl_deep_extend("force", defaults, opts or {})

  define_highlights()
  -- Reapply on colorscheme change so links stay valid
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = define_highlights,
  })

  -- Persist frecency data across sessions
  if cfg.persist_path then
    vim.api.nvim_create_autocmd("VimEnter", {
      once     = true,
      callback = function() frecency.load(cfg.persist_path) end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function() frecency.save(cfg.persist_path) end,
    })
  end

  -- Track buffer visits
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    callback = function(ev)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = ev.buf })
      if ft ~= "frecency_tab" then
        frecency.record_visit(ev.buf)
      end
    end,
  })

  -- Keymaps
  local map_opts = { noremap = true, silent = true }
  if cfg.keymaps.open then
    vim.keymap.set("n", cfg.keymaps.open, ui.open,
      vim.tbl_extend("force", map_opts, { desc = "Frecency Tab: open picker" }))
  end
  if cfg.keymaps.open_reverse then
    vim.keymap.set("n", cfg.keymaps.open_reverse, ui.open,
      vim.tbl_extend("force", map_opts, { desc = "Frecency Tab: open picker (reverse)" }))
  end
end

M.frecency = frecency
M.ui       = ui

return M
