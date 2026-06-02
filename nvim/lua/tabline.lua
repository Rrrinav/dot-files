local M = {}

local icons = {
  tab      = "▎",
  modified = "●",
  readonly = "",
  close    = "×",
  tab_nr   = "",
}

local function safe(fn, ...)
  local ok, val = pcall(fn, ...)
  if ok and type(val) == "string" then return val end
  return ""
end

local function hl(group, text)
  if not text or text == "" then return "" end
  return "%#" .. group .. "#" .. text .. "%*"
end

local function tab_bufnr(tabnr)
  local ok, winid = pcall(vim.api.nvim_tabpage_get_win, tabnr)
  if ok then
    local bok, bufnr = pcall(vim.api.nvim_win_get_buf, winid)
    if bok then return bufnr end
  end
  local wins = vim.api.nvim_tabpage_list_wins(tabnr)
  for _, w in ipairs(wins) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].buflisted then return b end
  end
  return vim.api.nvim_get_current_buf()
end

local function buf_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return "[No Name]" end
  return vim.fn.fnamemodify(name, ":t"):gsub("%%", "%%%%")
end

local function tab_modified(tabnr)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].modified then return true end
  end
  return false
end

local function tab_readonly(tabnr)
  local bufnr = tab_bufnr(tabnr)
  return vim.bo[bufnr].readonly
end

local function render_tab(tabnr, is_current)
  local bufnr   = tab_bufnr(tabnr)
  local name    = buf_name(bufnr)
  local total   = #vim.api.nvim_list_tabpages()

  -- choose highlight groups
  local grp_tab    = is_current and "TabLineSel"    or "TabLineInact"
  local grp_nr     = is_current and "TabLineNrSel"  or "TabLineNr"
  local grp_accent = is_current and "TabLineAccent" or "TabLineInact"
  local grp_mod    = is_current and "TabLineModSel" or "TabLineMod"

  -- left accent — only on active tab
  local accent = is_current and hl(grp_accent, icons.tab) or " "

  -- tab number — only show when more than one tab
  local nr_str = total > 1 and hl(grp_nr, tostring(tabnr) .. " ") or ""

  -- file icon / readonly marker
  local file_icon = tab_readonly(tabnr)
    and hl(grp_tab, icons.readonly .. " ")
    or  ""

  -- name
  local label = hl(grp_tab, name)

  -- modified dot
  local mod = tab_modified(tabnr) and hl(grp_mod, " " .. icons.modified) or ""

  -- padding
  local pad = hl(grp_tab, "  ")

  return accent .. pad .. nr_str .. file_icon .. label .. mod .. pad
end

function M.tabline()
  local tabs    = vim.api.nvim_list_tabpages()
  local current = vim.api.nvim_get_current_tabpage()

  -- Only show tabline when there is more than one tab.
  -- (If you always want it, remove this guard and set showtabline=2 in setup.)
  if #tabs <= 1 then return "" end

  local parts = {}
  for _, tabnr in ipairs(tabs) do
    local is_cur = (tabnr == current)
    parts[#parts + 1] = safe(render_tab, tabnr, is_cur)
  end

  -- fill the rest of the line with the inactive background
  return table.concat(parts, "") .. "%#TabLineFill#%="
end

function M.apply_highlights()
  local ok, palette = pcall(require, "config.palette")
  local p = ok and palette.colors or {}
  local bg     = p.bg     or "NONE"
  local bg_dim = p.bg2    or p.bg or "NONE"  -- slightly recessed bg for inactive

  local function set(name, spec)
    vim.api.nvim_set_hl(0, name, spec)
  end

  -- Active tab: fg2 for label + number (present, not shouting), no bold.
  -- Accent stays dim_plumbing — it marks position without competing.
  set("TabLineSel",    { fg = p.fg2          or "NONE", bg = bg })
  set("TabLineNrSel",  { fg = p.fg2          or "NONE", bg = bg })
  set("TabLineAccent", { fg = p.dim_plumbing or "NONE", bg = bg })
  set("TabLineModSel", { fg = p.error       or "NONE", bg = bg })

  -- Inactive tabs  ─────────────────────────────────────────────────────────────
  -- Dimmed fg on a slightly darker bg to recede visually.
  set("TabLineInact", { fg = p.dim_plumbing or "NONE", bg = bg_dim })
  set("TabLineNr",    { fg = p.dim_plumbing or "NONE", bg = bg_dim })
  set("TabLineMod",   { fg = p.warn         or "NONE", bg = bg_dim })

  -- Trailing fill  ─────────────────────────────────────────────────────────────
  set("TabLineFill", { fg = "NONE", bg = bg_dim })
end

-- ── Keymaps ───────────────────────────────────────────────────────────────────

local function set_keymaps()
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
  end

  map("]<Tab>"    ,   "<cmd>tabnext<cr>"    ,     "Tab: next")
  map("[<Tab>"    ,   "<cmd>tabprevious<cr>",     "Tab: prev")
  map("<leader>tn",   "<cmd>tabnew<cr>"     ,     "Tab: new")
  map("<leader>tc",   "<cmd>tabclose<cr>"   ,     "Tab: close")
  map("<leader>to",   "<cmd>tabonly<cr>"    ,     "Tab: close others")
  map("<leader>tb",   "<cmd>tab split<cr>"  ,     "Tab: open buffer in new tab")
  map("<leader>t<",   "<cmd>-tabmove<cr>"   ,     "Tab: new")
  map("<leader>t>",   "<cmd>+tabmove<cr>"   ,     "Tab: close")
end

function M.setup()
  M.apply_highlights()

  -- 1 = show only when >1 tab (matches the guard in M.tabline())
  -- Use 2 if you always want the tabline visible.
  vim.o.showtabline = 1
  vim.o.tabline     = "%!v:lua.require('tabline').tabline()"

  set_keymaps()

  local group = vim.api.nvim_create_augroup("TablineUpdates", { clear = true })

  vim.api.nvim_create_autocmd({
    "TabNew", "TabClosed", "TabEnter",
    "BufEnter", "BufWritePost", "BufModifiedSet",
  }, {
    group    = group,
    callback = function() vim.cmd.redrawtabline() end,
  })

  -- Keep highlights in sync with theme switches — same pattern as statusline
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = group,
    callback = M.apply_highlights,
  })
end

return M
