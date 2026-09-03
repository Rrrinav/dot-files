local M = {}

M.config = {
  position = "bottom",
  size = 17,
  auto_open = true,
  auto_jump = false,
  save_on_run = true,
  highlights = {
    error = "DiagnosticError",
    warning = "DiagnosticWarn",
    info = "DiagnosticInfo",
    success = "DiagnosticOk",
    dim = "Comment",
    cmd = "Statement",
  },
}

local state = {
  buf = nil,
  win = nil,
  job = nil,
  cwd = nil,
  cmd = nil,
  start_ms = 0,
  ns = vim.api.nvim_create_namespace("compile_clean"),
  line_map = {},
  spinner = nil,
}

local function clean_ansi(s)
  -- Removes standard CSI escapes (colors), OSC hyperlinks, and mode switches
  s = s:gsub("\27%[[%d;]*[a-zA-Z]", "")
  s = s:gsub("\27%]8;;.-\27\\", "")
  s = s:gsub("\27%[%?%d+[hl]", "")
  return s
end

local function classify(t)
  if not t or t == "" then return "I" end
  local lo = t:lower()
  if lo:match("err") or lo:match("fatal") or lo:match("panic") or lo:match("exception") then return "E" end
  if lo:match("warn") then return "W" end
  return "I"
end

local function is_absolute(path)
  -- Supports Unix absolute paths (/) and Windows drives (C:\ or C:/)
  return path:match("^/") or path:match("^%a:[/\\]")
end

---@class CompileLocation
---@field file string
---@field lnum integer
---@field col integer

-- Diverse pattern array covering majority of toolchains
local patterns = {
  -- 1. Standard (GCC, Clang, Go, TypeScript): file:10:5: error: msg
  { pat = "^%s*(.-):(%d+):(%d+):%s*(.*)",         f = 1, l = 2, c = 3,   m = 4 },
  -- 2. Standard no col: file:10: error: msg
  { pat = "^%s*(.-):(%d+):%s*(.*)",               f = 1, l = 2, c = nil, m = 3 },
  -- 3. MSVC / C# / MSBuild: file(10,5): error: msg
  { pat = "^%s*(.-)%((%d+),(%d+)%)%s*:%s*(.*)",   f = 1, l = 2, c = 3,   m = 4 },
  -- 4. MSVC no col: file(10): error: msg
  { pat = "^%s*(.-)%((%d+)%)%s*:%s*(.*)",         f = 1, l = 2, c = nil, m = 3 },
  -- 5. Rust: --> src/main.rs:12:3
  { pat = "^%s*-->%s*(.-):(%d+):(%d+)",           f = 1, l = 2, c = 3,   m = nil },
  -- 6. Python tracebacks: File "main.py", line 10, in <module>
  { pat = '^%s*File%s+"([^"]+)",%s*line%s*(%d+)', f = 1, l = 2, c = nil, m = nil },
  -- 7. Node.js stack trace: at Object.func (/path/to/file.js:10:5)
  { pat = "^%s*at%s+.-%((.-):(%d+):(%d+)%)",      f = 1, l = 2, c = 3,   m = nil },
  -- 8. Node.js bare stack trace: at /path/to/file.js:10:5
  { pat = "^%s*at%s+(.-):(%d+):(%d+)",            f = 1, l = 2, c = 3,   m = nil },
  -- 9. Node.js bare file path top-level: /path/to/file.js:1
  { pat = "^([/a-zA-Z~].-):(%d+):?(%d*)%s*$",     f = 1, l = 2, c = 3,   m = nil },
}

---@return string?, integer?, integer?, string?, integer?
local function parse_line(line)
  for _, p in ipairs(patterns) do
    local s_idx, e_idx, c1, c2, c3, c4 = line:find(p.pat)
    if s_idx then
      local caps = { c1, c2, c3, c4 }
      local f = caps[p.f]
      local l = tonumber(caps[p.l]) or 0
      local c = p.c and tonumber(caps[p.c]) or 0
      local m = p.m and caps[p.m] or ""

      if f and not f:match("^%s*$") then
        return f, l, c, classify(m), e_idx
      end
    end
  end

  -- Fallback: Catch raw exception/error names (like "ReferenceError:")
  -- so they get highlighted even if they don't have an attached file path.
  if line:match("^[A-Z]%a*Error:") or line:match("^[Ee]rror:") or line:match("^panic:") then
    return nil, 0, 0, "E", #line
  end

  return nil
end

local function set_status(text, hl)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.wo[state.win].statusline = string.format("%%#%s# %s ", hl or "Normal", text)
  end
end

-- Sleek braille spinner
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function start_spinner()
  if state.spinner then
    state.spinner:stop()
    state.spinner:close()
  end
  state.spinner = vim.uv.new_timer()
  local i = 1
  state.spinner:start(0, 80, vim.schedule_wrap(function()
    i = (i % #spinner_frames) + 1
    set_status(spinner_frames[i] .. " Compiling...", M.config.highlights.cmd)
  end))
end

local function stop_spinner(code, ms_taken)
  if state.spinner then
    state.spinner:stop()
    state.spinner:close()
    state.spinner = nil
  end
  local success = code == 0
  local status = success and "[OK] Success" or "[ERR] Failed"
  local hl = success and M.config.highlights.success or M.config.highlights.error
  set_status(string.format("%s [Exit: %d] (%.2fs)", status, code, ms_taken / 1000.0), hl)
end

local function ensure_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then return state.buf end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "compile"
  vim.api.nvim_buf_set_name(buf, "[Compile]")
  state.buf = buf
  return buf
end

-- Custom folding logic updated for new patterns
_G._compile_foldexpr = function(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^$") then return "0" end
  if parse_line(line) then return ">1" end
  if line:match("^%s") then return "1" end
  return "0"
end

local function open_win()
  local buf = ensure_buf()
  if state.win and vim.api.nvim_win_is_valid(state.win) then return state.win end

  if M.config.position == "float" then
    local w = math.floor(vim.o.columns * 0.8)
    local h = math.floor(vim.o.lines * 0.6)
    state.win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 2),
      col = math.floor((vim.o.columns - w) / 2),
      style = "minimal",
      border = "rounded",
    })
  else
    vim.cmd("botright " .. M.config.size .. "split")
    state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win, buf)
  end

  local w = state.win
  vim.wo[w].number = false
  vim.wo[w].relativenumber = false
  vim.wo[w].signcolumn = "no"
  vim.wo[w].wrap = false
  vim.wo[w].foldmethod = "expr"
  vim.wo[w].foldexpr = "v:lua._compile_foldexpr(v:lnum)"
  vim.wo[w].foldlevel = 99
  return w
end

local function append(lines)
  local buf = ensure_buf()
  vim.bo[buf].modifiable = true
  local start = vim.api.nvim_buf_line_count(buf)
  if start == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    start = 0
  end
  vim.api.nvim_buf_set_lines(buf, start, -1, false, lines)
  vim.bo[buf].modifiable = false
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_cursor(state.win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
  return start
end

local function clear()
  local buf = ensure_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)
  state.line_map = {}
end

local function jump_to_row(row)
  local item = state.line_map[row]
  if not item then return end
  local target
  for _, wid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if wid ~= state.win and vim.bo[vim.api.nvim_win_get_buf(wid)].buftype == "" then
      target = wid
      break
    end
  end
  if target then vim.api.nvim_set_current_win(target) else vim.cmd("wincmd p") end
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, item.col - 1) })
  vim.cmd("normal! zz")
end

local function stop_job()
  if state.job then
    vim.fn.jobstop(state.job)
    state.job = nil
  end
end

local function send_signal(sig)
  if state.job then
    local pid = vim.fn.jobpid(state.job)
    if pid and pid > 0 then
      vim.fn.system("kill -" .. sig .. " -- -" .. pid)
    end
  end
end

local function on_output(_, data)
  if not data then return end
  local lines = {}
  local hls = {}

  for _, raw in ipairs(data) do
    if raw ~= "" then
      local clean = clean_ansi(raw)
      table.insert(lines, clean)

      local f, l, c, t, pfx_len = parse_line(clean)

      if f then
        if not is_absolute(f) then f = state.cwd .. "/" .. f end
        f = vim.fs.normalize(f)

        local hl_map = { E = "error", W = "warning", I = "info" }
        table.insert(hls, {
          hl = M.config.highlights[hl_map[t]],
          len = pfx_len,
          item = { file = f, lnum = l, col = c }
        })
      elseif t then
        -- It is a standalone Error/Panic string (no file to jump to, but needs color)
        local hl_map = { E = "error", W = "warning", I = "info" }
        table.insert(hls, {
          hl = M.config.highlights[hl_map[t]],
          len = pfx_len,
          item = nil -- Not jumpable
        })
      else
        table.insert(hls, false)
      end
    end
  end

  if #lines == 0 then return end
  local start_idx = append(lines)

  for i, meta in ipairs(hls) do
    if meta then
      local row = start_idx + i - 1
      state.line_map[row] = meta.item
      pcall(vim.api.nvim_buf_set_extmark, state.buf, state.ns, row, 0, {
        end_col = meta.len,
        hl_group = meta.hl,
        strict = false
      })
    end
  end
end

local function run(cmd)
  if M.config.save_on_run then vim.cmd("silent! wall") end
  stop_job()

  state.cmd = cmd
  state.cwd = vim.fn.getcwd()
  state.start_ms = vim.uv.now()

  if M.config.auto_open then open_win() end
  clear()

  local time_str = os.date("%H:%M:%S")
  local short_cwd = vim.fn.fnamemodify(state.cwd, ":~")

  append({
    string.format("[%s] %s", time_str, short_cwd),
    "$ ▎" .. cmd,
    ""
  })

  pcall(vim.api.nvim_buf_set_extmark, state.buf, state.ns, 0, 0, {
    end_col = #time_str + #short_cwd + 3,
    hl_group = M.config.highlights.dim,
    strict = false
  })

  pcall(vim.api.nvim_buf_set_extmark, state.buf, state.ns, 1, 0, {
    end_col = #("$ ▎" .. cmd),
    hl_group = M.config.highlights.cmd,
    strict = false
  })

  start_spinner()

  state.job = vim.fn.jobstart({ "sh", "-c", cmd }, {
    cwd = state.cwd,
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(_, code)
      state.job = nil
      vim.schedule(function()
        local ms_taken = vim.uv.now() - state.start_ms
        stop_spinner(code, ms_taken)
        if M.config.auto_jump and next(state.line_map) then
          jump_to_row(next(state.line_map))
        end
      end)
    end,
  })
end

function M.compile(cmd)
  if not cmd or cmd == "" then
    cmd = vim.fn.input("Cmd: ", state.cmd or "", "shellcmd")
    if cmd == "" then return end
  end
  run(cmd)
end

function M.recompile()
  if state.cmd then run(state.cmd) else vim.notify("No previous command") end
end

function M.stop()
  if state.job then stop_job() end
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  else
    open_win()
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local function comp_complete(arglead, cmdline, cursorpos)
    local files = vim.fn.getcompletion(arglead, "file")
    local cmds  = vim.fn.getcompletion(arglead, "shellcmd")

    vim.list_extend(files, cmds)
    return files
  end

  vim.api.nvim_create_user_command("Comp", function(a) M.compile(a.args) end, { nargs = "*", complete = comp_complete, })
  vim.api.nvim_create_user_command("Recomp", M.recompile, {})
  vim.api.nvim_create_user_command("CompToggle", M.toggle, {})
  vim.api.nvim_create_user_command("CompStop", M.stop, {})

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "compile",
    callback = function(ev)
      local map = function(k, fn)
        vim.keymap.set("n", k, fn, { buffer = ev.buf, silent = true })
      end
      map("q", M.toggle)
      map("r", M.recompile)
      map("<C-c>", function() send_signal("INT") end)
      map("<C-d>", function() send_signal("TERM") end)
      map("<CR>", function() jump_to_row(vim.api.nvim_win_get_cursor(0)[1] - 1) end)
    end
  })
end

return M
