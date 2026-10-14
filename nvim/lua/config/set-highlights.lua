-- lua/config/set-highlights.lua

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

local function apply_bg(group, bg_color)
  local old = vim.api.nvim_get_hl(0, { name = group })

  -- Construct a fresh table to appease LuaLS and strip internal metadata
  ---@type vim.api.keyset.highlight
  local new_hl = {
    fg = old.fg,
    bg = bg_color, -- Inject our new background
    sp = old.sp,
    bold = old.bold,
    italic = old.italic,
    underline = old.underline,
    undercurl = old.undercurl,
    underdouble = old.underdouble,
    underdotted = old.underdotted,
    underdashed = old.underdashed,
    strikethrough = old.strikethrough,
    reverse = old.reverse,
    nocombine = old.nocombine,
  }

  vim.api.nvim_set_hl(0, group, new_hl)
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
  hl["PmenuSel"]                             = { bg = s.cursor_line, fg = p.string_pop }
  hl["PmenuSbar"]                            = { bg = p.bg }
  hl["PmenuThumb"]                           = { bg = p.dim_plumbing }
  apply_bg("PmenuKind", p.bg);

  -- Syntax: leave code to the active colorscheme.  The palette only separates
  -- things that should be immediately recognizable in every theme.
  hl["Comment"]                              = { fg = s.comment, italic = false }
  hl["@comment"]                             = { link = "Comment" }
  hl["@comment.documentation"]               = { link = "Comment" }
  hl["@comment.error"]                       = { link = "Comment" }
  hl["@comment.warning"]                     = { link = "Comment" }
  hl["@comment.todo"]                        = { link = "Comment" }
  hl["Todo"]                                 = { fg = p.info, bg = p.bg }
  hl["SpecialComment"]                       = { link = "Comment" }

  hl["String"]                               = { fg = p.string_pop }
  hl["@string"]                              = { fg = p.string_pop }
  hl["@string.documentation"]                = { fg = p.string_pop }
  hl["@string.escape"]                       = { fg = p.string_pop }
  hl["@string.regexp"]                       = { fg = p.string_pop }
  hl["@string.special"]                      = { fg = p.string_pop }
  hl["@string.special.symbol"]               = { fg = p.string_pop }
  hl["Character"]                            = { fg = p.string_pop }
  hl["@character"]                           = { fg = p.string_pop }
  hl["@character.special"]                   = { fg = p.string_pop }

  -- Do not override identifiers, keywords, types, constants,
  -- operators, punctuation, tags, or LSP semantic tokens here. Their hue and
  -- contrast come entirely from the colorscheme, so code remains cohesive when
  -- themes change instead of being recolored by this UI palette.
  -- Calls should use exactly the variable color, rather than a similar palette
  -- foreground. Cover Tree-sitter's generic and C++ captures, plus LSP semantic
  -- tokens, since the latter can take priority in C++ buffers.
  hl["@variable.cpp"]                        = { link = "@variable" }
  hl["@function.call"]                       = { link = "@variable" }
  hl["@function.method.call"]                = { link = "@variable" }
  hl["@function.call.cpp"]                   = { link = "@variable" }
  hl["@function.method.call.cpp"]            = { link = "@variable" }
  hl["@constructor"]                         = { link = "@variable" }
  hl["@constructor.cpp"]                     = { link = "@variable" }
  hl["@method.call"]                         = { link = "@variable" }
  hl["@lsp.type.function"]                   = { link = "@variable" }
  hl["@lsp.type.method"]                     = { link = "@variable" }
  hl["@lsp.typemod.function.defaultLibrary"] = { link = "@variable" }
  hl["@lsp.typemod.method.defaultLibrary"]   = { link = "@variable" }
  hl["@error"]                               = { fg = p.error }
  hl["Error"]                                = { fg = p.error }

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
  hl["CursorLineNr"]                         = { bg = s.cursor_line, fg = p.fg }
  hl["CursorLineSign"]                       = { bg = s.cursor_line }

  hl["Cursor"]                               = { fg = s.cursor_fg, bg = s.cursor_bg }
  hl["CursorReset"]                          = { fg = s.cursor_fg, bg = s.cursor_bg }
  hl["lcursor"]                              = { fg = s.cursor_fg, bg = s.cursor_bg }

  hl["Visual"]                               = { bg = s.visual }
  hl["Comment"]                              = { fg = s.comment, italic = false }

  hl["FloatBorder"]                          = { bg = p.bg, fg = p.dim_plumbing }
  hl["FloatTitle"]                           = { bg = p.bg, fg = p.fg }

  hl["LineNr"]                               = { bg = p.bg, fg = p.fg2 }
  hl["SignColumn"]                           = { bg = p.bg, fg = p.fg }
  hl["SignColumnSB"]                         = { bg = p.bg }

  hl["TabLineFill"]                          = { link = "Normal" }
  hl["TabLine"]                              = { bg = p.bg }
  hl["BufferLineFill"]                       = { bg = p.bg }
  hl["BufferLineIcon"]                       = { bg = p.bg }
  hl["BufferLineDevIconDefault"]             = { bg = p.bg }
  hl["BufferLineIconDefaultSelected"]        = { bg = p.bg }

  hl["Folded"]                               = { bg = s.cursor_line, fg = p.subtle }
  hl["FoldColumn"]                           = { bg = p.bg, fg = p.dim_plumbing }
  hl["CursorLineFold"]                       = { bg = s.cursor_line, fg = p.dim_plumbing }

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
  hl["TelescopeSelection"]                   = { bg = s.cursor_line }
  hl["TelescopeSelectionCaret"]              = { bg = s.cursor_line, fg = p.string_pop }
  hl["TelescopeMultiSelection"]              = { link = "Visual" }
  hl["TelescopeMatching"]                    = { fg = p.string_pop }

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

  -- Strip bolds+italics from colorscheme itself (kanagawa/gruvbox set Statement bold, Comment italic)
  -- Keep UI bolds (StatusLineMode) but clear syntax bolds/italics for minimal look.
  do
    local no_bi = {
      "Statement","Conditional","Repeat","Label","Operator","Keyword","Exception",
      "Constant","String","Character","Number","Boolean","Float",
      "Identifier","Function","Type","StorageClass","Structure","Typedef",
      "Special","SpecialChar","Tag","Delimiter","SpecialComment","Debug",
      "Underlined","Ignore","Error","Todo","Title","Comment",
      "@keyword","@type","@constant","@string","@comment","@function","@variable",
    }
    for _, g in ipairs(no_bi) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g })
      if not ok or not hl then goto continue end
      if hl.bold or hl.italic then
        local ok2, def = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
        if ok2 and def then
          def.bold = nil
          def.italic = nil
          local spec = {}
          for k, v in pairs(def) do
            if k ~= "bold" and k ~= "italic" then spec[k] = v end
          end
          spec.bold = false
          spec.italic = false
          pcall(vim.api.nvim_set_hl, 0, g, spec)
        else
          pcall(vim.api.nvim_set_hl, 0, g, { bold = false, italic = false })
        end
      end
      ::continue::
    end
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
