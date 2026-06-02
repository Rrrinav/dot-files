-- lua/config/highlights.lua

local M = {}
local palette = require("config.palette")

local function derive()
  local function get(group, attr)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    return (ok and hl[attr]) or nil
  end

  return {
    delimiter = get("Operator", "fg"),
  }
end

local function build_groups(p, s, d)
  local hl                                   = {}

  -- Editor Base
  hl["Normal"]                               = { bg = p.bg, fg = p.fg }
  hl["NormalNC"]                             = { bg = p.bg, fg = p.fg }
  hl["NormalFloat"]                          = { bg = p.bg, fg = p.fg }
  hl["NormalNCFloat"]                        = { bg = p.bg, fg = p.fg }
  hl["NormalPopup"]                          = { bg = p.bg, fg = p.fg }
  hl["NormalPopupFloat"]                     = { bg = p.bg, fg = p.fg }
  hl["NormalPopupNC"]                        = { bg = p.bg, fg = p.fg }
  hl["Float"]                                = { link = "Normal" }
  hl["EndOfBuffer"]                          = { bg = p.bg, fg = p.bg }
  hl["VertSplit"]                            = { bg = p.bg, fg = p.dim_plumbing }
  hl["WinSeparator"]                         = { bg = p.bg, fg = p.dim_plumbing }
  hl["StatusLine"]                           = { bg = p.bg, fg = p.dim_plumbing }
  hl["StatusLineNC"]                         = { bg = p.bg, fg = p.dim_plumbing }
  hl["IncSearch"]                            = { bg = p.fg2, fg = p.fg }

  hl["Pmenu"]                                = { bg = p.bg, fg = p.fg }
  hl["PmenuSel"]                             = { bg = s.cursor_line, fg = p.string_pop, bold = true }
  hl["PmenuSbar"]                            = { bg = p.bg }
  hl["PmenuThumb"]                           = { bg = p.dim_plumbing }

  -- LSP Semantic Modifiers
  hl["@lsp.typemod.method.defaultLibrary"]   = { link = "@function" }
  hl["@lsp.typemod.function.defaultLibrary"] = { link = "@function" }
  hl["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable" }
  hl["@lsp.typemod.class.defaultLibrary"]    = { link = "@type" }
  hl["@lsp.typemod.enum.defaultLibrary"]     = { link = "@type" }
  hl["@lsp.typemod.struct.defaultLibrary"]   = { link = "@type" }
  hl["@lsp.typemod.macro.defaultLibrary"]    = { link = "PreProc" }

  hl["@lsp.typemod.variable.readonly"]       = { link = "@variable" }
  hl["@lsp.typemod.property.readonly"]       = { link = "@property" }

  hl["@lsp.typemod.method.classScope"]       = { link = "@function" }
  hl["@lsp.typemod.variable.classScope"]     = { link = "@property" }

  -- The Dim
  hl["@punctuation.delimiter"]               = { fg = p.fg }
  hl["@punctuation.bracket"]                 = { fg = p.fg }
  hl["@punctuation.special"]                 = { fg = p.fg }

  -- The Base
  hl["Identifier"]                           = { fg = p.fg }
  hl["@variable"]                            = { fg = p.fg }
  hl["@property"]                            = { fg = p.fg }
  hl["@variable.parameter"]                  = { fg = p.fg }
  hl["Function"]                             = { fg = p.fg }
  hl["@function"]                            = { fg = p.fg }
  hl["@function.call"]                       = { fg = p.fg }
  hl["@function.method.call"]                = { fg = p.fg }
  hl["@method"]                              = { fg = p.fg }

  -- The Pop
  hl["String"]                               = { fg = p.string_pop }
  hl["@string"]                              = { fg = p.string_pop }

  -- Universal Diagnostics
  hl["DiagnosticError"]                      = { fg = p.error }
  hl["DiagnosticWarn"]                       = { fg = p.warn }
  hl["DiagnosticInfo"]                       = { fg = p.info }
  hl["DiagnosticHint"]                       = { fg = p.hint }

  hl["DiagnosticUnderlineError"]             = { sp = p.error, undercurl = true }
  hl["DiagnosticUnderlineWarn"]              = { sp = p.warn, undercurl = true }
  hl["DiagnosticUnderlineInfo"]              = { sp = p.info, undercurl = true }
  hl["DiagnosticUnderlineHint"]              = { sp = p.hint, undercurl = true }

  -- Git / Statusline Integration
  hl["StatusLineGitAdd"]                     = { fg = p.git_add, bg = p.bg }
  hl["StatusLineGitChange"]                  = { fg = p.git_change, bg = p.bg }
  hl["StatusLineGitDelete"]                  = { fg = p.git_delete, bg = p.bg }

  -- Explicitly forcing p.bg so it synchronizes with the SignColumn perfectly
  hl["GitSignsAdd"]                          = { fg = p.git_add, bg = p.bg }
  hl["GitSignsChange"]                       = { fg = p.git_change, bg = p.bg }
  hl["GitSignsDelete"]                       = { fg = p.git_delete, bg = p.bg }

  -- UI Elements
  hl["CursorLine"]                           = { bg = s.cursor_line }
  hl["CursorLineNr"]                         = { bg = s.cursor_line, fg = p.fg, bold = true }
  hl["CursorLineSign"]                       = { bg = s.cursor_line }

  hl["Cursor"]                               = { fg = s.cursor_fg, bg = s.cursor_bg }
  hl["CursorReset"]                          = { fg = s.cursor_fg, bg = s.cursor_bg }
  hl["lcursor"]                              = { fg = s.cursor_fg, bg = s.cursor_bg }

  hl["Visual"]                               = { bg = s.visual }
  hl["Comment"]                              = { fg = s.comment, italic = false }

  hl["FloatBorder"]                          = { bg = p.bg, fg = p.dim_plumbing }
  hl["FloatTitle"]                           = { bg = p.bg, fg = p.fg, bold = true }

  hl["LineNr"]                               = { bg = p.bg, fg = p.fg2 }
  hl["SignColumn"]                           = { bg = p.bg, fg = p.fg }
  hl["SignColumnSB"]                         = { bg = p.bg }

  hl["TabLineFill"]                          = { link = "Normal" }
  hl["TabLine"]                              = { bg = p.bg }
  hl["BufferLineFill"]                       = { bg = p.bg }
  hl["BufferLineIcon"]                       = { bg = p.bg }
  hl["BufferLineDevIconDefault"]             = { bg = p.bg }
  hl["BufferLineIconDefaultSelected"]        = { bg = p.bg }

  hl["Whitespace"]                           = { fg = s.whitespace }
  hl["SpecialKey"]                           = { fg = s.special_key }
  hl["NonText"]                              = { fg = s.non_text }
  hl["LspInlayHint"]                         = { bg = s.inlay_bg, fg = s.inlay_fg }

  -- Telescope
  hl["TelescopeTitle"]                       = { bg = p.bg, fg = p.subtle }
  hl["TelescopeNormal"]                      = { bg = p.bg, fg = p.fg }
  hl["TelescopeBorder"]                      = { bg = p.bg, fg = p.dim_plumbing }
  hl["TelescopePromptNormal"]                = { bg = p.bg, fg = p.fg }
  hl["TelescopePromptBorder"]                = { bg = p.bg, fg = p.dim_plumbing }
  hl["TelescopeResultsBorder"]               = { bg = p.bg, fg = p.dim_plumbing }
  hl["TelescopePreviewBorder"]               = { bg = p.bg, fg = p.dim_plumbing }
  hl["TelescopeResultsTitle"]                = { bg = p.bg, fg = p.fg }
  hl["TelescopePreviewTitle"]                = { bg = p.bg, fg = p.fg }
  hl["TelescopePromptTitle"]                 = { bg = p.bg, fg = p.fg }
  hl["TelescopePromptPrefix"]                = { link = "Normal" }
  hl["TelescopePromptCounter"]               = { bg = p.bg, fg = p.fg }
  hl["TelescopeResultsNormal"]               = { bg = p.bg, fg = p.fg }
  hl["TelescopePreviewNormal"]               = { bg = p.bg, fg = p.fg }
  hl["TelescopeSelection"]                   = { bg = s.cursor_line, bold = true }
  hl["TelescopeSelectionCaret"]              = { bg = s.cursor_line, fg = p.string_pop }
  hl["TelescopeMultiSelection"]              = { link = "Visual" }
  hl["TelescopeMatching"]                    = { fg = p.string_pop, bold = true }

  -- Plugins
  hl["TroubleNormal"]                        = { bg = p.bg, fg = p.fg }
  hl["WhichKeyBorder"]                       = { bg = p.bg, fg = p.dim_plumbing }
  hl["IblTabIndent"]                         = { fg = p.dim_plumbing, nocombine = true }
  hl["IblIndent"]                            = { fg = p.dim_plumbing, nocombine = true }
  hl["IblIndent"]                            = { fg = p.dim_plumbing, nocombine = true }

  return hl
end

-- Application Logic
local function apply()
  local p = palette.colors
  local s = palette.static
  local d = derive()

  -- Apply all main groups
  local groups = build_groups(p, s, d)
  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end

  -- Diagnostic signs: Explicitly set background to p.bg
  local diag_signs = {
    "DiagnosticSignError", "DiagnosticSignWarn",
    "DiagnosticSignInfo", "DiagnosticSignHint", "DiagnosticSignOk",
  }
  for _, name in ipairs(diag_signs) do
    local ok, existing = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    local fg = (ok and existing.fg) or nil
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = p.bg })
  end

  -- LspInlayHint
  do
    local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = "LspInlayHint", link = false })
    if ok then
      vim.api.nvim_set_hl(0, "LspInlayHint", {
        fg = s.inlay_fg, bg = s.inlay_bg, italic = false
      })
    end
  end

  -- Lualine
  local ok, lualine_auto = pcall(require, "lualine.themes.auto")
  if ok then
    local modes = { "normal", "insert", "visual", "replace", "command", "inactive", "terminal" }
    for _, mode in ipairs(modes) do
      lualine_auto[mode]      = lualine_auto[mode] or {}
      lualine_auto[mode].c    = lualine_auto[mode].c or {}
      lualine_auto[mode].c.bg = p.bg
    end
    local ok2, ll = pcall(require, "lualine")
    if ok2 then
      ll.setup({ options = { theme = lualine_auto } })
    end
  end
end

-- Live Theme Picker
local function open_theme_picker()
  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local entries      = {}
  for name, theme_data in pairs(palette.themes) do
    table.insert(entries, { name = name, theme = theme_data })
  end
  table.sort(entries, function(a, b) return a.name < b.name end)

  local original_colors = vim.deepcopy(palette.colors)
  local committed = false

  local function preview_theme(theme_data)
    for k in pairs(palette.colors) do
      palette.colors[k] = nil
    end
    for k, v in pairs(theme_data) do
      palette.colors[k] = v
    end
    apply()
  end

  pickers.new(require("telescope.themes").get_ivy({}), {
    prompt_title = "Theme Switcher  (Up/Down preview | Enter commit | Esc revert)",

    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value   = entry,
          display = string.format("%-22s  %s  %s", entry.name, entry.theme.bg, entry.theme.subtle),
          ordinal = entry.name,
        }
      end,
    }),

    sorter = conf.generic_sorter({}),

    attach_mappings = function(prompt_bufnr, map)
      local function preview_current()
        local sel = action_state.get_selected_entry()
        if sel then preview_theme(sel.value.theme) end
      end

      actions.move_selection_next:enhance({ post = preview_current })
      actions.move_selection_previous:enhance({ post = preview_current })
      actions.move_to_top:enhance({ post = preview_current })
      actions.move_to_bottom:enhance({ post = preview_current })
      actions.move_to_middle:enhance({ post = preview_current })

      vim.schedule(preview_current)

      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        committed = true
        actions.close(prompt_bufnr)
        if sel then
          preview_theme(sel.value.theme)
          vim.notify(
            string.format("[Theme] Switched to %s", sel.value.name),
            vim.log.levels.INFO
          )
        end
      end)

      local function cancel()
        committed = true
        palette.colors = vim.deepcopy(original_colors)
        apply()
        actions.close(prompt_bufnr)
      end

      map({ "i", "n" }, "<Esc>", cancel)
      map("n", "q", cancel)

      actions.close:enhance({
        post = function()
          if not committed then
            palette.colors = vim.deepcopy(original_colors)
            apply()
          end
        end,
      })

      return true
    end,
  }):find()
end

-- Setup
function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserHighlights", { clear = true }),
    callback = apply,
  })

  apply()

  vim.api.nvim_create_user_command("ThemeSwitch", open_theme_picker, {
    desc = "Live-preview and switch semantic color themes",
  })
end

return M
