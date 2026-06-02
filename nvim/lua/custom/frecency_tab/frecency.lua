-- frecency_tab/frecency.lua
-- Tracks buffer visits and computes frecency scores
-- Frecency = frequency weighted by recency (inspired by Mozilla's algorithm)

local M = {}

-- visit_log: { [bufnr] = { timestamps = [...], label = "..." } }
local visit_log = {}

local MAX_VISITS = 100          -- cap per buffer to avoid unbounded growth
local HALF_LIFE_MS = 3600000    -- 1 hour half-life for recency decay

---Record a visit to a buffer.
---@param bufnr integer
function M.record_visit(bufnr)
  if bufnr == nil or bufnr == 0 then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local now = vim.uv and vim.uv.hrtime() / 1e6 or vim.loop.hrtime() / 1e6

  if not visit_log[bufnr] then
    visit_log[bufnr] = { timestamps = {} }
  end

  local log = visit_log[bufnr]
  table.insert(log.timestamps, now)

  -- Trim oldest beyond MAX_VISITS
  while #log.timestamps > MAX_VISITS do
    table.remove(log.timestamps, 1)
  end
end

---Compute frecency score for a buffer.
--- score = sum over visits of: 2 ^ (-(age_ms / HALF_LIFE_MS))
---@param bufnr integer
---@return number
function M.score(bufnr)
  if not visit_log[bufnr] then return 0 end
  local now = vim.uv and vim.uv.hrtime() / 1e6 or vim.loop.hrtime() / 1e6
  local s = 0
  for _, ts in ipairs(visit_log[bufnr].timestamps) do
    local age = now - ts
    s = s + 2 ^ -(age / HALF_LIFE_MS)
  end
  return s
end

---Return sorted list of valid, named buffers by frecency score (desc).
---@return { bufnr: integer, score: number, name: string, short: string }[]
function M.ranked_buffers()
  local results = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      -- Only real files: skip [Pager]/[Dialog]/etc, oil://, term://, unlisted
      local is_real = name and name ~= ""
        and not name:match("^%[")     -- [Pager], [Dialog], [Cmd] …
        and not name:match("^%a+://") -- oil://, term://, man:// …
        and vim.fn.filereadable(name) == 1
      if is_real then
        local short = vim.fn.fnamemodify(name, ":~:.")
        table.insert(results, {
          bufnr = bufnr,
          score = M.score(bufnr),
          name  = name,
          short = short,
        })
      end
    end
  end
  table.sort(results, function(a, b) return a.score > b.score end)
  return results
end

---Persist visit log to a file (JSON-like, lightweight).
---@param path string
function M.save(path)
  local lines = {}
  for bufnr, data in pairs(visit_log) do
    -- store as "bufname\ttimestamp,timestamp,..."
    local name = vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_get_name(bufnr) or nil
    if name and name ~= "" then
      table.insert(lines, name .. "\t" .. table.concat(data.timestamps, ","))
    end
  end
  local f = io.open(path, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
end

---Load visit log from a file.
---@param path string
function M.load(path)
  local f = io.open(path, "r")
  if not f then return end
  for line in f:lines() do
    local name, ts_str = line:match("^(.+)\t(.+)$")
    if name and ts_str then
      -- Find matching buffer by name
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(bufnr) == name then
          local timestamps = {}
          for ts in ts_str:gmatch("[^,]+") do
            table.insert(timestamps, tonumber(ts))
          end
          visit_log[bufnr] = { timestamps = timestamps }
          break
        end
      end
    end
  end
  f:close()
end

return M
