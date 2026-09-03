require('kanagawa').setup({
  compile = false,  -- enable compiling the colorscheme
  undercurl = true, -- enable undercurls
  commentStyle = { italic = false },
  functionStyle = {},
  keywordStyle = { italic = false },
  statementStyle = { bold = true },
  typeStyle = {},
  transparent = false,   -- do not set background color
  dimInactive = true,    -- dim inactive window `:h hl-NormalNC`
  terminalColors = true, -- define vim.g.terminal_color_{0,17}
  colors = {             -- add/modify theme and palette colors
    palette = {},
    theme = { wave = {}, lotus = {}, dragon = {}, all = { ui = { bg_gutter = "none" } } },
  },
  overrides = function(colors) -- add/modify highlights
    return {}
  end,
  theme = "dragon",  -- Load "wave" theme
  background = {     -- map the value of 'background' option to a theme
    dark = "dragon", -- try "dragon" !
    light = "lotus"
  },
})

require("gruvbox").setup();

vim.g.mellow_italic_comments     = false;
vim.g.mellow_italic_keywords     = false;
vim.g.mellow_italic_booleans     = false;
vim.g.mellow_italic_functions    = false;
vim.g.mellow_italic_variables    = false;
vim.g.mellow_italic_namespaces   = false;

vim.g.mellow_highlight_overrides = {
  ["Type"] = { fg = "#A383D6" },
  ["Function"] = { fg = "#96ebc3" },
  ["String"] = { fg = "#E7D36F" }
}

require('onedark').setup({
  highlights = {
    CursorLine = { bg = '#41454f' },
  },
  code_style = {
    comments = 'none',
    keywords = 'none',
    functions = 'none',
    strings = 'none',
    variables = 'none'
  },
})


require('gitsigns').setup {
  signs = {
    add = { text = "│" }, -- Thin vertical bar
    change = { text = "│" }, -- Same as add for consistency
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "┆" },
    untracked = { text = "┆" }, -- Dotted vertical bar
  },
  signs_staged = {
    add = { text = "┃" }, -- Bold vertical bar
    change = { text = "┃" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "┃" },
  },
  signs_staged_enable = true,       -- Enable staged signs
  signcolumn = true,                -- Toggle with `:Gitsigns toggle_signs`
  numhl = false,                    -- Toggle with `:Gitsigns toggle_numhl`
  linehl = false,                   -- Toggle with `:Gitsigns toggle_linehl`
  word_diff = false,                -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  }, on_attach = function(buffer)
  local gs = package.loaded.gitsigns

  local function map(mode, l, r, desc)
    vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
  end

  -- stylua: ignore start
  map("n", "]h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      gs.nav_hunk("next")
    end
  end, "Next Hunk")
  map("n", "[h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      gs.nav_hunk("prev")
    end
  end, "Prev Hunk")
end,
  auto_attach                  = true,
  attach_to_untracked          = false,
  current_line_blame           = false,       -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts      = {
    virt_text = true,
    virt_text_pos = 'eol',       -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority                = 6,
  update_debounce              = 100,
  status_formatter             = nil,         -- Use default
  max_file_length              = 40000,       -- Disable if file is longer than this (in lines)
  preview_config               = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 3
  },
}

require("marks").setup({
  default_mappings  = true,
  builtin_marks     = { ".", "<", ">", "^" },
  cyclic            = true,
  force_write_shada = false,
  bookmark_0        = { sign = "⚑", virt_text = "marked" },
})

local neoscroll = require("neoscroll")
neoscroll.setup({
  mappings             = {}, -- was <C-u>/<C-d> conflict with snacks.scroll; keep snacks for most buffers, neoscroll only on demand
  hide_cursor          = false,
  stop_eof             = true,
  respect_scrolloff    = true, -- was false, respect scrolloff=8 from basic_gui
  cursor_scrolls_alone = true,
})
-- <C-u>/<C-d> now handled by snacks.scroll (snacks.lua:20); keep neoscroll for <C-b>/<C-f> only
vim.keymap.set({ "n", "v", "x" }, "<C-b>", function() neoscroll.ctrl_b({ duration = 80, easing = "sine" }) end)
vim.keymap.set({ "n", "v", "x" }, "<C-f>", function() neoscroll.ctrl_f({ duration = 80, easing = "sine" }) end)

require("csvview").setup({
  parser = {
    async_chunksize = 50,
    delimiter       = { default = ",", ft = { tsv = "\t" } },
    quote_char      = '"',
    comments        = {},
  },
  view = {
    min_column_width = 5,
    spacing          = 2,
    display_mode     = "border",
    header_lnum      = 1,
    sticky_header    = { enabled = true, separator = "─" },
  },
})
