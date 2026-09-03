-- config/options.lua - extracted from basic_gui.lua
-- Pure vim.opt / vim.o settings, no side-effects beyond options.

local M = {}

function M.setup()
  -- Cursor & font
  vim.opt.guicursor = "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50,n-v:blinkwait500-blinkoff250-blinkon200-Cursor/lCursor"
  vim.opt.guifont = "JetBrainsMono Nerd Font"

  -- Cursor highlights (moved here because they are tied to guicursor)
  vim.api.nvim_set_hl(0, "Cursor", { fg = "#fff1da", bg = "#fff1da" })
  vim.api.nvim_set_hl(0, "CursorReset", { fg = "#fff1da", bg = "#fff1da" })
  vim.api.nvim_set_hl(0, "lcursor", { fg = "#fff1da", bg = "#fff1da" })

  -- UI
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.o.signcolumn = "yes"
  vim.opt.showmatch = false
  vim.opt.termguicolors = true
  vim.opt.matchtime = 0

  vim.opt.fillchars = {
    eob = " ",
    fold = " ",
    foldopen = "",
    foldclose = "",
    foldsep = "│",
    vert = "│",
    horiz = "─",
    horizup = "┴",
    horizdown = "┬",
    vertleft = "┤",
    vertright = "├",
    verthoriz = "┼",
  }

  vim.opt.winblend = 10
  vim.opt.numberwidth = 6
  vim.opt.foldcolumn = "0"

  -- Indentation (global defaults; filetype autocmds in autocmds.lua may override per-buffer)
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 4
  vim.opt.tabstop = 4
  vim.opt.softtabstop = 4
  vim.opt.smartindent = false
  vim.opt.wrap = false
  vim.opt.breakindent = false

  -- Search
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.hlsearch = true
  vim.opt.incsearch = true

  -- Editor behavior
  vim.opt.hidden = true
  vim.opt.clipboard = "unnamedplus"
  vim.opt.mouse = "a"
  vim.opt.undofile = true
  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.updatetime = 250
  vim.opt.timeoutlen = 300
  vim.opt.completeopt = "menuone,noselect"
  vim.o.linebreak = true

  -- Whitespace
  vim.opt.list = true
  vim.opt.listchars = {
    lead = " ",
    tab = "» ",
    trail = "-",
    extends = "›",
    precedes = "‹",
  }

  -- Window management
  vim.o.splitbelow = true
  vim.o.splitright = true
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  vim.opt.statuscolumn = "%r %l %s"

  -- Folding: LSP with treesitter fallback + pretty text
  _G._custom_foldexpr = function()
    local lsp = vim.lsp.foldexpr()
    if lsp ~= "0" and lsp ~= 0 and lsp ~= "" then return lsp end
    local ok, ts = pcall(function() return vim.treesitter.foldexpr() end)
    if ok and ts ~= "0" and ts ~= 0 and ts ~= "" then return ts end
    return "0"
  end
  _G._custom_foldtext = function()
    local n = vim.v.foldend - vim.v.foldstart + 1
    local indent = string.rep(" ", vim.fn.indent(vim.v.foldstart))
    return string.format("%s> fold: %d ---", indent, n)
  end
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua._G._custom_foldexpr()"
  vim.opt.foldenable = true
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldtext = "v:lua._G._custom_foldtext()"
  vim.opt.foldcolumn = "0"

  -- File handling
  vim.bo.modifiable = true
  vim.opt.fileencoding = "utf-8"
  vim.opt.swapfile = false

  -- Whitespace / UI highlights
  vim.api.nvim_set_hl(0, "Whitespace", { fg = "#4444aa" })
  vim.api.nvim_set_hl(0, "SpecialKey", { fg = "#88a888" })
  vim.api.nvim_set_hl(0, "NonText", { fg = "#666666" })

  -- Neovide GUI
  if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font:h11"
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_animation_length = 0.06
    vim.g.neovide_cursor_trail_size = 0.0
    vim.g.neovide_refresh_rate = 60
    vim.g.neovide_fullscreen = false
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_scale_factor = 1.0
  end

  -- Experimental ui2
  pcall(function()
    require("vim._core.ui2").enable({
      enable = true,
      msg = {
        targets = "cmd",
        cmd = { height = 0.5 },
        dialog = { height = 0.5 },
        msg = { height = 0.5, timeout = 4000 },
        pager = { height = 1 },
      },
    })
  end)
end

return M
