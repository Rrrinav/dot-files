-- custom/outline.lua - minimal aerial-like outline, no external plugin
-- Uses LSP documentSymbol if available, fallback to treesitter queries.
-- Keeps your minimal palette: only uses Type/Function/Constant hues via existing hl groups.

local M = {}

local state = {
  buf = nil,
  win = nil,
  items = {}, -- { name, kind, lnum, col, end_lnum }
  ns = vim.api.nvim_create_namespace("custom_outline"),
}

local kind_icons = {
  File = "󰈔", Module = "󰅩", Namespace = "󱡠", Package = "󰅩",
  Class = "󱡠", Method = "󰊕", Property = "󰖷", Field = "󰜢",
  Constructor = "󰒓", Enum = "󰦨", Interface = "󱡠", Function = "󰊕",
  Variable = "󰆦", Constant = "󰏿", String = "󰉿", Number = "󰎠",
  Boolean = "󰏿", Array = "󰅪", Object = "󰅩", Key = "󰌋",
  Null = "󰟢", EnumMember = "󰦨", Struct = "󱡠", Event = "󱐋",
  Operator = "󰪚", TypeParameter = "󰬛",
}

local kind_hl = {
  Class = "Type", Struct = "Type", Enum = "Type", Interface = "Type",
  Function = "Function", Method = "Function", Constructor = "Function",
  Field = "@property", Property = "@property", Variable = "@variable",
  Constant = "Constant", Number = "Number", String = "String",
  Array = "Type", Object = "Type", Key = "@property",
  EnumMember = "Constant", Namespace = "Tag", Module = "Include",
  Package = "Include", Boolean = "Boolean",
}

-- Try LSP documentSymbol
local function lsp_symbols(bufnr, callback)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  -- filter clients that support documentSymbol
  local has = false
  for _, c in ipairs(clients) do
    if c.server_capabilities.documentSymbolProvider then has = true; break end
  end
  if not has or #clients == 0 then callback(nil) return end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
    if err or not result or vim.tbl_isempty(result) then callback(nil); return end

    local items = {}
    local function flatten(syms, depth)
      depth = depth or 0
      for _, s in ipairs(syms) do
        local kind = vim.lsp.protocol.SymbolKind[s.kind] or "Unknown"
        local range = s.range or s.location and s.location.range
        if range then
          table.insert(items, {
            name = s.name,
            kind = kind,
            lnum = range.start.line + 1,
            col = range.start.character + 1,
            end_lnum = range["end"].line + 1,
            depth = depth,
          })
        end
        if s.children then flatten(s.children, depth + 1) end
      end
    end
    flatten(result, 0)
    callback(items)
  end)
end

-- Treesitter fallback: per-filetype queries for defs
local ts_queries = {
  c = [[
    (function_definition declarator: (function_declarator declarator: (identifier) @name)) @func
    (class_specifier name: (type_identifier) @name) @class
    (struct_specifier name: (type_identifier) @name) @struct
    (enum_specifier name: (type_identifier) @name) @enum
  ]],
  cpp = [[
    (function_definition declarator: (function_declarator declarator: (_) @name)) @func
    (class_specifier name: (type_identifier) @name) @class
    (struct_specifier name: (type_identifier) @name) @struct
    (enum_specifier name: (type_identifier) @name) @enum
    (field_declaration declarator: (field_identifier) @name) @field
  ]],
  lua = [[
    (function_declaration name: (_) @name) @func
    (function_definition name: (_) @name) @func
    (assignment_statement (variable_list name: (identifier) @name) (expression_list value: (function_definition))) @func
  ]],
  python = [[
    (function_definition name: (identifier) @name) @func
    (class_definition name: (identifier) @name) @class
  ]],
  rust = [[
    (function_item name: (identifier) @name) @func
    (struct_item name: (type_identifier) @name) @struct
    (enum_item name: (type_identifier) @name) @enum
    (impl_item type: (type_identifier) @name) @class
  ]],
  go = [[
    (function_declaration name: (identifier) @name) @func
    (method_declaration name: (field_identifier) @name) @func
    (type_declaration (type_spec name: (type_identifier) @name)) @type
  ]],
}

local function ts_symbols(bufnr)
  local ft = vim.bo[bufnr].filetype
  local qstr = ts_queries[ft]
  if qstr then
    local lang = vim.treesitter.language.get_lang(ft) or ft
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if ok and parser then
      local tree = parser:parse()[1]
      if tree then
        local root = tree:root()
        local ok2, query = pcall(vim.treesitter.query.parse, lang, qstr)
        if ok2 and query then
          local kind_map = { func = "Function", class = "Class", struct = "Struct", enum = "Enum", field = "Field", type = "Type" }
          local items = {}
          for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
            local cap = query.captures[id]
            local kind = kind_map[cap]
            if kind then
              local srow, scol = node:range()
              local text = vim.treesitter.get_node_text(node, bufnr)
              table.insert(items, {
                name = text, kind = kind, lnum = srow + 1, col = scol + 1, end_lnum = srow + 1, depth = 0,
              })
            end
          end
          if #items > 0 then return items end
        end
      end
    end
  end
  -- Regex fallback when treesitter not available or no matches - still useful for outline
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local items = {}
  for i, line in ipairs(lines) do
    local name, kind
    if ft == "cpp" or ft == "c" then
      name = line:match("^%s*class%s+([%w_]+)") or line:match("^%s*struct%s+([%w_]+)") or line:match("^%s*enum%s+([%w_]+)")
      if name then kind = line:match("^%s*class") and "Class" or line:match("^%s*struct") and "Struct" or "Enum"
      else
        -- function: capture last word before '('
        local f = line:match("^%s*[%w_:<>~&%*]+%s+([%w_:]+)%s*%(")
        if f and not line:match("^%s*if%s*%(") and not line:match("^%s*for%s*%(") and not line:match("^%s*while%s*%(") then name, kind = f, "Function" end
      end
    elseif ft == "lua" then
      name = line:match("^%s*function%s+([%w_%.:]+)%s*%(") or line:match("^%s*local%s+function%s+([%w_%.:]+)%s*%(")
      if name then kind = "Function" end
    elseif ft == "python" then
      name = line:match("^%s*def%s+([%w_]+)%s*%(") or line:match("^%s*class%s+([%w_]+)")
      if name then kind = line:match("^%s*def") and "Function" or "Class" end
    elseif ft == "rust" then
      name = line:match("^%s*fn%s+([%w_]+)%s*%(") or line:match("^%s*struct%s+([%w_]+)") or line:match("^%s*enum%s+([%w_]+)")
      if name then kind = line:match("^%s*fn") and "Function" or line:match("^%s*struct") and "Struct" or "Enum" end
    elseif ft == "go" then
      name = line:match("^%s*func%s+.-([%w_]+)%s*%(") or line:match("^%s*type%s+([%w_]+)%s+struct")
      if name then kind = line:match("^%s*func") and "Function" or "Struct" end
    end
    if name and kind then
      table.insert(items, { name = name, kind = kind, lnum = i, col = 1, end_lnum = i, depth = 0 })
    end
  end
  if #items == 0 then return nil end
  return items
end

local function ensure_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then return state.buf end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "outline"
  vim.api.nvim_buf_set_name(buf, "Outline")
  state.buf = buf
  return buf
end

local function render(items, bufnr)
  local buf = ensure_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)
  local lines = {}
  state.items = {}
  if not items or #items == 0 then
    lines = { "  — no symbols —", "", "  LSP: " .. (vim.lsp.get_clients({ bufnr = bufnr })[1] and "no symbols" or "no client"), "  Treesitter: " .. (ts_queries[vim.bo[bufnr].filetype] and "no matches" or "no query for " .. vim.bo[bufnr].filetype) }
  else
    for i, it in ipairs(items) do
      local icon = kind_icons[it.kind] or "·"
      local indent = string.rep("  ", it.depth or 0)
      local line = string.format("%s%s %s  %d", indent, icon, it.name, it.lnum)
      table.insert(lines, line)
      state.items[i] = it
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- highlight icons after lines are set
  for i, it in ipairs(state.items) do
    local icon = kind_icons[it.kind] or "·"
    local indent = string.rep("  ", it.depth or 0)
    local hl = kind_hl[it.kind] or "Normal"
    -- icon byte length for extmark
    local icon_len = #icon
    pcall(vim.api.nvim_buf_set_extmark, buf, state.ns, i-1, #indent, { end_col = #indent + icon_len, hl_group = hl })
  end
  vim.bo[buf].modifiable = false
end

local function jump(idx)
  local it = state.items[idx]
  if not it then return end
  -- find target window (not outline)
  local target = nil
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) ~= state.buf then
      -- prefer normal buftype window
      if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then target = w; break end
      if not target then target = w end
    end
  end
  if target then vim.api.nvim_set_current_win(target) end
  vim.api.nvim_win_set_cursor(0, { it.lnum, math.max(0, it.col - 1) })
  vim.cmd("normal! zz")
end

local function open_win()
  local buf = ensure_buf()
  if state.win and vim.api.nvim_win_is_valid(state.win) then return state.win end
  vim.cmd("vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, buf)
  vim.wo[state.win].winfixwidth = true
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].foldmethod = "expr"
  vim.wo[state.win].foldexpr = "v:lua._outline_foldexpr(v:lnum)"
  vim.wo[state.win].foldenable = true
  vim.wo[state.win].foldlevel = 99
  vim.wo[state.win].foldcolumn = "0"
  vim.api.nvim_win_set_width(state.win, 36)
  return state.win
end

local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    close()
    return
  end
  M.open()
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then
    vim.notify("Outline: not a file buffer", vim.log.levels.WARN)
    return
  end
  open_win()
  -- try LSP first, fallback to treesitter
  lsp_symbols(bufnr, function(items)
    if items and #items > 0 then
      vim.schedule(function() render(items, bufnr) end)
    else
      local ts_items = ts_symbols(bufnr)
      vim.schedule(function() render(ts_items, bufnr) end)
    end
  end)
  -- if LSP is slow, show at least ts quickly
  local ts_now = ts_symbols(bufnr)
  if ts_now and #ts_now > 0 then render(ts_now, bufnr) end
end

-- Fold expr for outline: uses depth from state.items
_G._outline_foldexpr = function(lnum)
  local it = state.items[lnum]
  local nxt = state.items[lnum + 1]
  if not it then return "0" end
  if nxt and nxt.depth > it.depth then
    return ">" .. (it.depth + 1)
  end
  return tostring(it.depth)
end

function M.setup(opts)
  opts = opts or {}
  -- no keymaps - use :CodeOutline

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "outline",
    callback = function(ev)
      vim.keymap.set("n", "q", close, { buffer = ev.buf, silent = true, desc = "Outline: close" })
      vim.keymap.set("n", "<CR>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        jump(row)
      end, { buffer = ev.buf, silent = true, desc = "Outline: jump" })
      vim.keymap.set("n", "<Esc>", close, { buffer = ev.buf, silent = true })
      -- folding keys
      vim.keymap.set("n", "za", "za", { buffer = ev.buf, silent = true, desc = "Outline: toggle fold" })
      vim.keymap.set("n", "zo", "zo", { buffer = ev.buf, silent = true })
      vim.keymap.set("n", "zc", "zc", { buffer = ev.buf, silent = true })
      vim.keymap.set("n", "zM", "zM", { buffer = ev.buf, silent = true })
      vim.keymap.set("n", "zR", "zR", { buffer = ev.buf, silent = true })
    end,
  })

  vim.api.nvim_create_user_command("CodeOutline", M.toggle, { desc = "Toggle code outline (LSP/Treesitter, foldable)" })
  vim.api.nvim_create_user_command("CodeOutlineOpen", M.open, { desc = "Open code outline" })
  vim.api.nvim_create_user_command("CodeOutlineClose", close, { desc = "Close code outline" })
end

return M
