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
  return s:gsub("\27%[[%d;]*[A-Za-z]", "")
end

local function classify(t)
  local lo = t:lower()
  if lo:match("err") or lo:match("fatal") then return "E" end
  if lo:match("warn") then return "W" end
  return "I"
end

---@class CompileLocation
---@field file string
---@field lnum integer
---@field col integer

---@return string?, integer?, integer?, string?, integer?
local function parse_line(line)
  -- Regex 1: file:line:col: severity: msg
  local pfx, f, l, c, t = line:match("^(([^:]+):(%d+):(%d+):%s*(%a+):%s*).*$")
  if pfx then return f, tonumber(l) or 0, tonumber(c) or 0, classify(t), #pfx end

  -- Regex 2: file:line:col: msg
  local pfx2, f2, l2, c2, m2 = line:match("^(([^:]+):(%d+):(%d+):%s*)(.*)$")
  if pfx2 then return f2, tonumber(l2) or 0, tonumber(c2) or 0, classify(m2), #pfx2 end

  -- Regex 3: file:line: msg
  local pfx3, f3, l3, m3 = line:match("^(([^:]+):(%d+):%s*)(.*)$")
  if pfx3 then return f3, tonumber(l3) or 0, 0, classify(m3), #pfx3 end
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

-- Custom folding logic
_G._compile_foldexpr = function(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^$") then return "0" end
  if line:match("^[^:]+:%d+:") then return ">1" end
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
        if not f:match("^/") then f = state.cwd .. "/" .. f end
        local hl_map = { E = "error", W = "warning", I = "info" }
        table.insert(hls, {
          hl = M.config.highlights[hl_map[t]],
          len = pfx_len,
          item = { file = f, lnum = l, col = c }
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
    end_col = #cmd + 2,
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
