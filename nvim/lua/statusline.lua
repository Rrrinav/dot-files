-- statusline.lua
-- Usage: require("statusline").setup() in your init.lua
-- Requires a Nerd Font + config.palette

local M = {}

local icons = {
  diagnostics = { Error = " ", Warn = " ", Info = " ", Hint = " " },
  git         = { added = " +", modified = " ~", removed = " -" },
  branch      = "",
  lsp         = " ",
  file        = " ",
  readonly    = " ",
  modified    = " ●",
  location    = " ",
}

local mode_map = {
  n = "N", no = "N", nov = "N",
  v = "V", V = "VL", ["\22"] = "VB",
  s = "S", S = "SL", ["\19"] = "SB",
  i = "I", ic = "I", ix = "I",
  R = "R", Rv = "VR",
  c = "C", cv = "EX", ce = "EX",
  r = "P", rm = "M", ["r?"] = "?",
  ["!"] = "SH", t = "T",
}

-- Helpers

local function get_ctx()
  local winid = vim.g.statusline_winid
  if not winid or type(winid) ~= "number" then
    winid = vim.api.nvim_get_current_win()
  end
  local ok, bufnr = pcall(vim.api.nvim_win_get_buf, winid)
  if not ok then bufnr = vim.api.nvim_get_current_buf() end
  return winid, bufnr
end

local function safe(fn, ...)
  local ok, val = pcall(fn, ...)
  if ok and type(val) == "string" then return val end
  return ""
end

local function hl(group, text)
  if not text or text == "" then return "" end
  return "%#" .. group .. "#" .. text .. "%*"
end

local div = hl("StatusLineDivider", "  │  ")

local function join(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local s = select(i, ...)
    if type(s) == "string" and s ~= "" then
      parts[#parts + 1] = s
    end
  end
  return table.concat(parts, div)
end

local function spacejoin(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local s = select(i, ...)
    if type(s) == "string" and s ~= "" then
      parts[#parts + 1] = s
    end
  end
  return table.concat(parts, " ")
end

-- Segments

local function mode()
  local m = vim.api.nvim_get_mode().mode
  local str = mode_map[m] or m
  -- mode color is derived per-render from palette in apply_highlights
  -- but we still need a per-mode group for the string_pop vs info distinction
  local group = ({
    N = "StatusLineModeN", I = "StatusLineModeI",
    V = "StatusLineModeV", VL = "StatusLineModeV", VB = "StatusLineModeV",
    C = "StatusLineModeC", R = "StatusLineModeR", VR = "StatusLineModeR",
    T = "StatusLineModeT",
  })[str] or "StatusLineModeN"
  return hl(group, str)
end

local function branch(bufnr)
  local b
  local ok
  ok, b = pcall(function() return vim.b[bufnr].gitsigns_head end)
  if ok and b and b ~= "" then goto found end
  ok, b = pcall(function() return vim.g.gitsigns_head end)
  if ok and b and b ~= "" then goto found end
  do
    local head = vim.fn.findfile(".git/HEAD", vim.fn.getcwd() .. ";")
    if head == "" then return "" end
    local f = io.open(head, "r")
    if not f then return "" end
    local line = f:read("*l"); f:close()
    b = line and line:match("ref: refs/heads/(.+)")
    if not b then return "" end
  end
  ::found::
  return hl("StatusLineBranch", icons.branch .. " " .. b:gsub("%%", "%%%%"))
end

local function filepath(bufnr)
  local full = vim.api.nvim_buf_get_name(bufnr)
  local ok, bo = pcall(function() return vim.bo[bufnr] end)
  local modified = ok and bo and bo.modified
  local readonly  = ok and bo and bo.readonly

  local icon = readonly and icons.readonly or icons.file
  local path = full == "" and "[No Name]"
    or vim.fn.fnamemodify(full, ":~:."):gsub("%%", "%%%%")

  local out = hl("StatusLineFile", icon .. path)
  if modified then out = out .. hl("StatusLineModified", icons.modified) end
  return out
end

local function diagnostics(bufnr)
  local diags = vim.diagnostic.get(bufnr)
  if #diags == 0 then return "" end

  local counts = { E = 0, W = 0, I = 0, H = 0 }
  for _, d in ipairs(diags) do
    if     d.severity == 1 then counts.E = counts.E + 1
    elseif d.severity == 2 then counts.W = counts.W + 1
    elseif d.severity == 3 then counts.I = counts.I + 1
    elseif d.severity == 4 then counts.H = counts.H + 1
    end
  end

  local parts = {}
  if counts.E > 0 then parts[#parts+1] = hl("DiagnosticError", icons.diagnostics.Error .. "E" .. counts.E) end
  if counts.W > 0 then parts[#parts+1] = hl("DiagnosticWarn",  icons.diagnostics.Warn  .. "W" .. counts.W) end
  if counts.I > 0 then parts[#parts+1] = hl("DiagnosticInfo",  icons.diagnostics.Info  .. "I" .. counts.I) end
  if counts.H > 0 then parts[#parts+1] = hl("DiagnosticHint",  icons.diagnostics.Hint  .. "H" .. counts.H) end
  return table.concat(parts, "")
end

local function git_diff(bufnr)
  local ok, gs = pcall(function() return vim.b[bufnr].gitsigns_status_dict end)
  if not ok or not gs then return "" end

  local parts = {}
  if (gs.added   or 0) > 0 then parts[#parts+1] = hl("StatusLineGitAdd",    icons.git.added    .. gs.added)   end
  if (gs.changed or 0) > 0 then parts[#parts+1] = hl("StatusLineGitChange", icons.git.modified .. gs.changed) end
  if (gs.removed or 0) > 0 then parts[#parts+1] = hl("StatusLineGitDelete", icons.git.removed  .. gs.removed) end
  return table.concat(parts, " ")
end

local excluded = { ["null-ls"] = true, copilot = true }
local function lsp_clients(bufnr)
  local get = vim.lsp.get_clients or vim.lsp.get_active_clients
  if not get then return "" end
  local ok, clients = pcall(get, { bufnr = bufnr })
  if not ok or not clients then return "" end

  local names = {}
  for _, c in pairs(clients) do
    if c and c.name and not excluded[c.name] then
      names[#names + 1] = c.name
    end
  end
  if #names == 0 then return "" end
  return hl("StatusLineLsp", icons.lsp .. table.concat(names, " "):gsub("%%", "%%%%"))
end

local function location(winid, bufnr)
  local ok, cur_pos = pcall(vim.api.nvim_win_get_cursor, winid)
  if not ok then return "" end

  local row = cur_pos[1]
  local col = cur_pos[2] + 1

  if vim.api.nvim_get_mode().mode:find("^[vV\22]") then
    local chars = (vim.fn.wordcount().visual_chars or 0)
    return hl("StatusLineLoc", icons.location .. row .. ":" .. col .. "  " .. chars .. "c")
  end

  return hl("StatusLineLoc", icons.location .. row .. ":" .. col)
end

-- Assembly

function M.statusline()
  local winid, bufnr = get_ctx()

  local left = join(
    safe(mode),
    safe(branch, bufnr),
    spacejoin(safe(filepath, bufnr), safe(diagnostics, bufnr))
  )

  local right = join(
    safe(git_diff, bufnr),
    safe(lsp_clients, bufnr),
    safe(location, winid, bufnr)
  )

  return " " .. left .. "%=" .. right .. " "
end

-- Highlight application — reads live from palette.colors every call

function M.apply_highlights()
  local ok, palette = pcall(require, "config.palette")
  local p = ok and palette.colors or {}
  local bg = p.bg or "NONE"

  local function set(name, spec)
    spec.bg = spec.bg or bg
    vim.api.nvim_set_hl(0, name, spec)
  end

  -- Mode: use semantic palette colors
  -- N → dim_plumbing (subtle, it's the default)
  -- I → string_pop (your "pop" color, stands out naturally)
  -- V → info
  -- C → warn
  -- R → error
  -- T → dim_plumbing
  set("StatusLineModeN", { fg = p.dim_plumbing or "NONE", bold = true })
  set("StatusLineModeI", { fg = p.string_pop   or "NONE", bold = true })
  set("StatusLineModeV", { fg = p.info         or "NONE", bold = true })
  set("StatusLineModeC", { fg = p.warn         or "NONE", bold = true })
  set("StatusLineModeR", { fg = p.error        or "NONE", bold = true })
  set("StatusLineModeT", { fg = p.dim_plumbing or "NONE", bold = true })

  -- Branch + LSP + location: dim_plumbing — present but not competing
  set("StatusLineBranch",  { fg = p.dim_plumbing or "NONE" })
  set("StatusLineLsp",     { fg = p.fg2 or "NONE" })
  set("StatusLineLoc",     { fg = p.fg2 or "NONE" })
  set("StatusLineDivider", { fg = p.fg2 or "NONE" })

  -- File: full fg — this is the primary info
  set("StatusLineFile",     { fg = p.fg    or "NONE" })
  set("StatusLineModified", { fg = p.error or "NONE" })

  -- Git diffs: use palette git colors (already set by highlights.lua but
  -- we re-set with explicit bg so they don't bleed on the statusline)
  set("StatusLineGitAdd",    { fg = p.git_add    or "NONE" })
  set("StatusLineGitChange", { fg = p.git_change or "NONE" })
  set("StatusLineGitDelete", { fg = p.git_delete or "NONE" })

  -- Diagnostics piggyback DiagnosticError/Warn/Info/Hint which
  -- highlights.lua already sets — no need to redefine them here
end

function M.setup()
  M.apply_highlights()

  vim.o.laststatus = 3
  vim.o.showmode   = false
  vim.o.statusline = "%!v:lua.require('statusline').statusline()"

  local group = vim.api.nvim_create_augroup("StatuslineUpdates", { clear = true })

  -- Redraw on editor events
  vim.api.nvim_create_autocmd({
    "ModeChanged", "BufEnter", "BufWritePost",
    "DiagnosticChanged", "LspAttach", "LspDetach",
    "CursorMoved", "CursorMovedI",
  }, {
    group    = group,
    callback = function() vim.cmd.redrawstatus() end,
  })

  vim.api.nvim_create_autocmd("User", {
    group   = group,
    pattern = "GitSignsUpdate",
    callback = function() vim.cmd.redrawstatus() end,
  })

  -- Re-apply highlights whenever the theme switcher fires ColorScheme
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = group,
    callback = M.apply_highlights,
  })

  -- Also hook into your ThemeSwitch flow — palette.colors mutates in place
  -- so re-applying after any highlights.lua apply() call is enough.
  -- If you want instant sync without ColorScheme, call M.apply_highlights()
  -- at the end of your highlights.lua apply() function too.
end

return M
