-- frecency_tab/ui.lua
local M = {}
local frecency = require("custom.frecency_tab.frecency")

local state = {
  win    = nil,
  buf    = nil,
  ns     = vim.api.nvim_create_namespace("frecency_tab"),
  items  = {},
  cursor = 1,
  origin = nil,
  active = false,
  name_w = 0,
}

local GUTTER = 4

local function layout(n_items)
  local ui_w  = vim.o.columns
  local ui_h  = vim.o.lines
  local width  = math.min(math.floor(ui_w * 0.52), 68)
  local height = math.max(math.min(n_items, 12), 1)
  local row    = math.floor((ui_h - height) / 2) - 1
  local col    = math.floor((ui_w - width - GUTTER) / 2)
  return width, height, row, col
end

local function getopt(bufnr, name)
  return vim.api.nvim_get_option_value(name, { buf = bufnr })
end

local function setopt(bufnr, name, value)
  vim.api.nvim_set_option_value(name, value, { buf = bufnr })
end

-- ── render ────────────────────────────────────────────────────────────────────

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  local items = state.items
  local lines = {}

  for _, item in ipairs(items) do
    local short    = item.short
    local modified = getopt(item.bufnr, "modified")

    if modified then
      local max = state.name_w - 2
      if #short > max then short = "…" .. short:sub(-(max - 1)) end
      table.insert(lines, short .. " ●")
    else
      if #short > state.name_w then
        short = "…" .. short:sub(-(state.name_w - 1))
      end
      table.insert(lines, short)
    end
  end

  setopt(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  setopt(state.buf, "modifiable", false)

  -- highlights via extmarks (nvim_buf_add_highlight is deprecated)
  vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
  for i, item in ipairs(items) do
    local lnum = i - 1
    local hl   = (i == state.cursor) and "FrecencySelected" or "FrecencyItem"

    vim.api.nvim_buf_set_extmark(state.buf, state.ns, lnum, 0, {
      end_row      = lnum,
      end_col      = #lines[i],
      hl_group     = hl,
      hl_eol       = true,   -- extend highlight to end of line
      priority     = 10,
    })

    if getopt(item.bufnr, "modified") then
      local dot_byte = #lines[i] - 3  -- ● is 3 UTF-8 bytes
      local mod_hl   = (i == state.cursor) and "FrecencyModifiedSel" or "FrecencyModified"
      vim.api.nvim_buf_set_extmark(state.buf, state.ns, lnum, dot_byte, {
        end_row  = lnum,
        end_col  = dot_byte + 3,
        hl_group = mod_hl,
        priority = 11,
      })
    end
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_cursor(state.win, { state.cursor, 0 })
  end
end

-- ── open / close / navigation ─────────────────────────────────────────────────

local function close(switch_to)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win    = nil
  state.buf    = nil
  state.active = false
  if switch_to then
    vim.api.nvim_set_current_buf(switch_to)
    frecency.record_visit(switch_to)
  end
end

local function move_cursor(delta)
  local n = #state.items
  if n == 0 then return end
  state.cursor = ((state.cursor - 1 + delta) % n) + 1
  render()
end

local function confirm()
  local item = state.items[state.cursor]
  close(item and item.bufnr or nil)
end

local function setup_keymaps()
  local opts = { nowait = true, noremap = true, silent = true, buffer = state.buf }
  local map  = function(lhs, fn) vim.keymap.set("n", lhs, fn, opts) end

  map("<Tab>",     function() move_cursor(1)  end)
  map("<S-Tab>",   function() move_cursor(-1) end)
  map("<C-Tab>",   function() move_cursor(1)  end)
  map("<C-S-Tab>", function() move_cursor(-1) end)
  map("j",         function() move_cursor(1)  end)
  map("k",         function() move_cursor(-1) end)
  map("<CR>",      confirm)
  map("<Esc>",     function() close() end)
  map("q",         function() close() end)

  for i = 1, 9 do
    map(tostring(i), function()
      if state.items[i] then state.cursor = i; confirm() end
    end)
  end
end

function M.open()
  if state.active then move_cursor(1); return end

  state.origin = vim.api.nvim_get_current_buf()
  state.items  = frecency.ranked_buffers()
  state.cursor = 1

  if #state.items > 1 and state.items[1].bufnr == state.origin then
    state.cursor = 2
  end

  if #state.items == 0 then
    vim.notify("frecency-tab: no file buffers open", vim.log.levels.INFO)
    return
  end

  local width, height, row, col = layout(#state.items)
  state.name_w = width

  state.buf = vim.api.nvim_create_buf(false, true)
  setopt(state.buf, "bufhidden", "wipe")
  setopt(state.buf, "filetype",  "frecency_tab")

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
    border   = "single",
    zindex   = 50,
  })

  vim.wo[state.win].number         = true
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].cursorline     = false
  vim.wo[state.win].wrap           = false
  vim.wo[state.win].signcolumn     = "no"
  vim.wo[state.win].foldcolumn     = "0"
  vim.wo[state.win].statuscolumn   = ""
  vim.wo[state.win].winhighlight   =
    "Normal:FrecencyNormal,FloatBorder:FrecencyBorder," ..
    "LineNr:FrecencyLineNr,CursorLineNr:FrecencyLineNr"

  setup_keymaps()
  state.active = true
  render()

  -- Ensure we land in normal mode — prevents the "press Enter twice" issue
  -- that happens when the picker opens while a <CR> mapping is still resolving
  vim.cmd("stopinsert")
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Ignore>", true, false, true), "n", false)

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer   = state.buf,
    once     = true,
    callback = function() close() end,
  })
end

return M
