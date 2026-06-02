local M = {}

function M.setup()
  -- current cursor config
  vim.opt.guicursor =
  "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50,n-v:blinkwait500-blinkoff250-blinkon200-Cursor/lCursor"

  -- block cursor for everything
  -- vim.opt.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20,n-v:blinkwait500-blinkoff250-blinkon200-Cursor/lCursor"
  vim.opt.guifont = "JetBrainsMono Nerd Font"

  -- Define the highlight groups
  local crusor_fg = "#cc9900"
  local white_alt = "#fff1da"
 
  vim.api.nvim_set_hl(0, "Cursor", { fg = white_alt, bg = "#fff1da" })
  vim.api.nvim_set_hl(0, "CursorReset", { fg = white_alt, bg = "#fff1da" })
  vim.api.nvim_set_hl(0, "lcursor", { fg = white_alt, bg = "#fff1da" })

  vim.diagnostic.config({
  })

  vim.opt.number         = true
  vim.opt.relativenumber = true
  vim.opt.cursorline     = true
  vim.o.signcolumn       = "yes"
  vim.opt.showmatch      = false-- Highlight matching parentheses
  vim.opt.termguicolors  = true -- Enable true color support
  vim.opt.matchtime      = 0


  vim.opt.fillchars = {
    eob       = "~", -- Replace `~` with space on empty lines
    fold      = " ", -- Clean folding markers
    vert      = "│", -- Vertical separator
    horiz     = "─", -- Horizontal separator
    horizup   = "┴", -- Top horizontal separator
    horizdown = "┬", -- Bottom horizontal separator
    vertleft  = "┤", -- Left vertical separator
    vertright = "├", -- Right vertical separator
    verthoriz = "┼", -- Cross separator
  }


  vim.opt.winblend    = 10 -- Adjust the transparency level (0-100)
  vim.opt.numberwidth = 6

  -- Indentation
  vim.opt.expandtab   = true  -- Use spaces instead of tabs
  vim.opt.shiftwidth  = 4     -- Indent by 2 spaces
  vim.opt.tabstop     = 4     -- Tab width
  vim.opt.softtabstop = 4     -- Make spaces feel like tabs
  vim.opt.smartindent = false -- Enable smart indentation
  vim.opt.wrap        = false -- Disable line wrapping
  vim.opt.breakindent = false -- Maintain indent when wrapping


  -- Search
  vim.opt.ignorecase = true -- Ignore case when searching
  vim.opt.smartcase  = true -- Override ignorecase when using uppercase
  vim.opt.hlsearch   = true -- Highlight search results
  vim.opt.incsearch  = true -- Show search matches as you type


  -- Editor behavior
  vim.opt.hidden      = true               -- Allow switching buffers without saving
  vim.opt.clipboard   = "unnamedplus"      -- Use system clipboard
  vim.opt.mouse       = "a"                -- Enable mouse support
  vim.opt.undofile    = true               -- Persistent undo history
  vim.opt.backup      = false              -- Disable backup files
  vim.opt.writebackup = false              -- Disable backup files
  vim.opt.updatetime  = 250                -- Faster completion
  vim.opt.timeoutlen  = 300                -- Faster key sequence completion
  vim.opt.completeopt = "menuone,noselect" -- Better completion experience
  vim.o.linebreak     = true

  -- Show whitespace
  vim.opt.list        = true
  vim.opt.listchars = {
    lead = ' ', -- ·
    tab = '» ',
    trail = '-',
    extends = '›',
    precedes = '‹',
  }

  -- Window management
  vim.o.splitbelow       = true -- Split windows below
  vim.o.splitright       = true -- Split windows right
  vim.opt.scrolloff      = 8   -- Minimal number of lines to keep above/below cursor
  vim.opt.sidescrolloff  = 8   -- Minimal number of columns to keep left/right of cursor

  vim.opt.statuscolumn   = "%r %l %s"

  -- Make sure folding is enabled but starts unfolded
  vim.opt.foldenable     = true
  vim.opt.foldlevel      = 99
  vim.opt.foldmethod     = "expr"
  vim.opt.foldexpr       = "v:lua.vim.lsp.foldexpr()"
  vim.opt.foldenable     = true
  vim.opt.foldlevel      = 99 -- Start with all folds open
  vim.opt.foldlevelstart = 99 -- Start with all folds open
  vim.opt.foldtext       = ""


  -- File handling
  vim.bo.modifiable    = true
  vim.opt.fileencoding = "utf-8" -- Use UTF-8 encoding
  vim.opt.swapfile     = false   -- Disable swap files

  vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    signs = {
      -- text = {
      --   [vim.diagnostic.severity.ERROR] = " ",
      --   [vim.diagnostic.severity.WARN] = " ",
      --   [vim.diagnostic.severity.HINT] = " ",
      --   [vim.diagnostic.severity.INFO] = " ",
      -- },
      severity = {
        min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
      },
    },
    virtual_text = {
      virt_text_pos = "eol_right_align", -- Align to end of line and right-align
      current_line = true,
      source = "if_many",
      prefix = "",
      severity = {
        min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
      },
    },
    underline = {
      severity = {
        min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
      },
    },
  })

  -- vim.diagnostic.config({
  --   update_in_insert = false,
  --   severity_sort = true,
  --   virtual_lines = {
  --     current_line = true,
  --     source = "if_many",
  --     severity = {
  --       min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
  --     },
  --   },
  --   signs = {
  --     severity = {
  --       min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
  --     },
  --   },
  --   underline = {
  --     severity = {
  --       min = vim.diagnostic.severity.WARN, -- Show only WARN and above (hide HINT)
  --     },
  --   },
  -- })
-- Global state to keep track of mode
  local use_virtual_text = true

  local function swap_diagnostics()
    use_virtual_text = not use_virtual_text

    if use_virtual_text then
      vim.diagnostic.config({
        virtual_text = {
          virt_text_pos = "eol_right_align",
          current_line = true,
          source = "if_many",
          severity = {
            min = vim.diagnostic.severity.WARN,
          },
        },
        virtual_lines = false,
      })
      vim.notify("Diagnostics: using virtual_text", vim.log.levels.INFO)
    else
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = {
          current_line = true,
          source = "if_many",
          severity = {
            min = vim.diagnostic.severity.WARN,
          },
        },
      })
      vim.notify("Diagnostics: using virtual_lines", vim.log.levels.INFO)
    end
  end

  vim.api.nvim_set_hl(0, "Whitespace", {
    fg = "#4444aa",
  })

  vim.api.nvim_set_hl(0, "SpecialKey", {
    fg = "#88a888",   -- tabs
  })

  vim.api.nvim_set_hl(0, "NonText", {
    fg = "#666666",
  })
  -- Keymap to toggle diagnostics display
  vim.keymap.set("n", "<leader>xv", swap_diagnostics, { desc = "Toggle virtual_text / virtual_lines" })

  if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font:h12:Thin"

    -- General GUI tweaks
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_animation_length = 0.06
    vim.g.neovide_cursor_trail_size = 0.0
    vim.g.neovide_refresh_rate = 60
    vim.g.neovide_fullscreen = false
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_scale_factor = 0.8

    vim.g.neovide_scale_factor = 1.0
  end


  require('vim._core.ui2').enable({
    enable = true, -- Whether to enable or disable the UI.
    msg = {      -- Options related to the message module.
      ---@type 'cmd'|'msg' Default message target, either in the
      ---cmdline or in a separate ephemeral message window.
      ---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
      ---or table mapping |ui-messages| kinds and triggers to a target.
      targets = 'cmd',
      cmd = {         -- Options related to messages in the cmdline window.
        height = 0.5  -- Maximum height while expanded for messages beyond 'cmdheight'.
      },
      dialog = {      -- Options related to dialog window.
        height = 0.5, -- Maximum height.
      },
      msg = {         -- Options related to msg window.
        height = 0.5, -- Maximum height.
        timeout = 4000, -- Time a message is visible in the message window.
      },
      pager = {       -- Options related to message window.
        height = 1,   -- Maximum height.
      },
    },
  })
end

return M
