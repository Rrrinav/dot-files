-- swap_words.lua
-- Swap words/selections atomically with undo-safe transactions and visual mode support.
--
-- Keybindings (normal mode):
--   <leader>C  : Save word under cursor (press again to cancel)
--   <leader>R  : Swap saved word with word under cursor
--   <A-m>      : Swap word under cursor with next word (rightward)
--   <A-M>      : Swap word under cursor with previous word (leftward)
--
-- Keybindings (visual mode):
--   <leader>C  : Save visual selection (press again to cancel)
--   <leader>R  : Swap saved selection with current visual selection

local M = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

--- Run `fn`. If it throws, restore `snapshot` lines and re-raise.
--- All edits inside `fn` are collapsed into one undo entry.
---@param bufnr integer
---@param start_row integer  0-indexed, inclusive
---@param end_row integer    0-indexed, inclusive
---@param fn function
local function atomic(bufnr, start_row, end_row, fn)
  -- Snapshot the affected lines so we can roll back on error
  local snapshot = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

  -- Break any pending undojoin chain before we start our own block
  -- (pcall because this errors if there's nothing to join yet)
  pcall(vim.cmd, "normal! i\027") -- tiny no-op to anchor undo sequence

  local ok, err = pcall(fn)

  if not ok then
    -- Rollback: restore lines exactly as they were
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, snapshot)
    -- Merge the rollback into the same undo block so undo does nothing visible
    pcall(vim.cmd, "undojoin")
    error(err, 0)
  end
end

--- Replace text in a buffer at a byte range. Handles multi-line selections.
---@param bufnr integer
---@param start_row integer  0-indexed
---@param start_col integer  0-indexed byte col
---@param end_row integer    0-indexed
---@param end_col integer    0-indexed byte col (exclusive)
---@param replacement string
local function buf_replace(bufnr, start_row, start_col, end_row, end_col, replacement)
  local lines = vim.split(replacement, "\n", { plain = true })
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
end

--- Get the byte range of the word under the cursor.
--- Returns start_row, start_col, end_row, end_col (0-indexed, end exclusive).
---@return integer, integer, integer, integer
local function cword_range()
  local pos = vim.api.nvim_win_get_cursor(0) -- {1-indexed row, 0-indexed col}
  local row = pos[1] - 1
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]

  -- [%w_] mirrors Vim's default iskeyword (alphanumeric + underscore)
  local function is_keyword(ch) return ch:match("[%w_]") ~= nil end

  -- Find word start (walk left)
  local col = pos[2]
  while col > 0 and is_keyword(line:sub(col, col)) do
    col = col - 1
  end
  if not is_keyword(line:sub(col + 1, col + 1)) then col = col + 1 end
  local start_col = col

  -- Find word end (walk right)
  local end_col = pos[2] + 1
  while end_col <= #line and is_keyword(line:sub(end_col + 1, end_col + 1)) do
    end_col = end_col + 1
  end

  return row, start_col, row, end_col
end

--- Get the text covered by a byte range.
---@return string
local function buf_get_text(bufnr, start_row, start_col, end_row, end_col)
  local chunks = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  return table.concat(chunks, "\n")
end

-- ─── State ────────────────────────────────────────────────────────────────────

---@class SwapSlot
---@field mark_id integer   extmark id anchoring the slot
---@field text string       text content of the slot
---@field ns integer

--- Plant an extmark that tracks a range. Returns the mark id.
---@param ns integer
---@param bufnr integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return integer
local function plant_mark(ns, bufnr, start_row, start_col, end_row, end_col)
  return vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
    end_row = end_row,
    end_col = end_col,
    hl_group = "IncSearch",
    -- Extmark moves with the text automatically
    right_gravity = false,
    end_right_gravity = true,
  })
end

--- Retrieve live position of an extmark (returns start+end since we stored end).
---@return integer, integer, integer, integer  start_row, start_col, end_row, end_col
local function mark_range(ns, bufnr, mark_id)
  local info = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
  if not info or #info == 0 then
    error("Extmark lost — buffer may have been modified externally.")
  end
  return info[1], info[2], info[3].end_row, info[3].end_col
end

-- ─── Core ─────────────────────────────────────────────────────────────────────

function M.setup()
  local ns = vim.api.nvim_create_namespace("SwapWords")

  ---@type SwapSlot|nil
  local slot = nil

  local function clear_slot()
    if slot then
      pcall(vim.api.nvim_buf_del_extmark, 0, ns, slot.mark_id)
      slot = nil
    end
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end

  --- Save a range as the swap slot.
  local function save_range(bufnr, start_row, start_col, end_row, end_col)
    -- If a slot is already saved, cancel (toggle behaviour)
    if slot then
      clear_slot()
      vim.notify("[swap] Cancelled.", vim.log.levels.INFO)
      return
    end

    local text = buf_get_text(bufnr, start_row, start_col, end_row, end_col)
    if text == "" then
      vim.notify("[swap] Nothing to save (empty selection).", vim.log.levels.WARN)
      return
    end

    local mark_id = plant_mark(ns, bufnr, start_row, start_col, end_row, end_col)
    slot = { mark_id = mark_id, text = text, ns = ns }
    vim.notify(("[swap] Saved: %q"):format(text), vim.log.levels.INFO)
  end

  --- Perform the swap between slot and a target range — atomically.
  local function do_swap(bufnr, t_sr, t_sc, t_er, t_ec)
    if not slot then
      vim.notify("[swap] No word/selection saved. Use <leader>C first.", vim.log.levels.WARN)
      return
    end

    local target_text = buf_get_text(bufnr, t_sr, t_sc, t_er, t_ec)
    if target_text == "" then
      vim.notify("[swap] Target is empty.", vim.log.levels.WARN)
      return
    end

    -- Retrieve live slot range (extmark tracks shifts from earlier edits)
    local s_sr, s_sc, s_er, s_ec = mark_range(ns, bufnr, slot.mark_id)
    local saved_text = slot.text

    -- We need to know which range comes first in the buffer to avoid
    -- corrupting positions when we do two replacements.
    local slot_first = (s_sr < t_sr) or (s_sr == t_sr and s_sc <= t_sc)

    -- Determine the outermost row span for our snapshot
    local snap_start = math.min(s_sr, t_sr)
    local snap_end   = math.max(s_er, t_er)

    -- Guard: don't allow overlapping ranges
    local function ranges_overlap()
      -- Simple row/col overlap check
      local function before(r1, c1, r2, c2) return r1 < r2 or (r1 == r2 and c1 < c2) end
      return not (before(s_er, s_ec, t_sr, t_sc) or before(t_er, t_ec, s_sr, s_sc))
    end
    if ranges_overlap() then
      vim.notify("[swap] Ranges overlap — cannot swap.", vim.log.levels.WARN)
      return
    end

    local saved_cursor = vim.api.nvim_win_get_cursor(0)

    local ok, err = pcall(atomic, bufnr, snap_start, snap_end, function()
      if slot_first then
        -- Replace target first (it's after slot, so slot's extmark is unaffected)
        buf_replace(bufnr, t_sr, t_sc, t_er, t_ec, saved_text)
        -- Now retrieve slot position (extmark auto-adjusted if needed)
        local sr, sc, er, ec = mark_range(ns, bufnr, slot.mark_id)
        buf_replace(bufnr, sr, sc, er, ec, target_text)
      else
        -- Replace slot first (it's after target)
        local sr, sc, er, ec = mark_range(ns, bufnr, slot.mark_id)
        buf_replace(bufnr, sr, sc, er, ec, target_text)
        -- Target position is unaffected
        buf_replace(bufnr, t_sr, t_sc, t_er, t_ec, saved_text)
      end
    end)

    if not ok then
      vim.notify(("[swap] Error during swap: %s"):format(err), vim.log.levels.ERROR)
    end

    clear_slot()

    -- Restore cursor to where the user was (now containing the swapped-in text)
    pcall(vim.api.nvim_win_set_cursor, 0, saved_cursor)
  end

  -- ─── Normal-mode: word operations ───────────────────────────────────────────

  local function save_cword()
    local row, sc, er, ec = cword_range()
    save_range(0, row, sc, er, ec)
  end

  local function swap_cword()
    local row, sc, er, ec = cword_range()
    do_swap(0, row, sc, er, ec)
  end

  -- ─── Visual-mode: selection operations ──────────────────────────────────────

  local function visual_range()
    -- Exit visual mode to set '< and '> marks
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "x", false)

    local start_pos = vim.api.nvim_buf_get_mark(0, "<")
    local end_pos   = vim.api.nvim_buf_get_mark(0, ">")
    -- Marks are 1-indexed rows; nvim_buf_get_text wants 0-indexed
    local sr = start_pos[1] - 1
    local sc = start_pos[2]
    local er = end_pos[1] - 1
    -- end_pos col from '>' is inclusive; nvim_buf_get_text end_col is exclusive
    local line = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or ""
    local ec = math.min(end_pos[2] + 1, #line)
    return sr, sc, er, ec
  end

  local function save_visual()
    local sr, sc, er, ec = visual_range()
    save_range(0, sr, sc, er, ec)
  end

  local function swap_visual()
    local sr, sc, er, ec = visual_range()
    do_swap(0, sr, sc, er, ec)
  end

  -- ─── Word-navigation helpers (unchanged logic, cleaned up) ──────────────────

  local function move_to_next_word()
    local init = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! w")
    for _ = 1, 100 do
      local pos  = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1] or ""
      local ch   = line:sub(pos[2] + 1, pos[2] + 1)
      if not (ch:match("^%p$") or ch:match("^%s$")) then return end
      if pos[2] + 1 >= #line then
        vim.api.nvim_win_set_cursor(0, init)
        return
      end
      vim.cmd("normal! w")
    end
  end

  local function move_to_prev_word()
    local init = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! b")
    for _ = 1, 100 do
      local pos  = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1] or ""
      local ch   = line:sub(pos[2] + 1, pos[2] + 1)
      if not (ch:match("^%p$") or ch:match("^%s$")) then return end
      if pos[2] == 0 then
        vim.api.nvim_win_set_cursor(0, init)
        return
      end
      vim.cmd("normal! b")
    end
  end

  -- ─── Keybindings ────────────────────────────────────────────────────────────

  -- Normal mode
  vim.keymap.set("n", "<leader>C", save_cword,
    { desc = "[swap] Save word under cursor" })

  vim.keymap.set("n", "<leader>R", swap_cword,
    { desc = "[swap] Swap word under cursor with saved word" })

  vim.keymap.set("n", "<A-m>", function()
    save_cword()
    move_to_next_word()
    swap_cword()
  end, { noremap = true, silent = true, desc = "[swap] Swap word rightward" })

  vim.keymap.set("n", "<A-M>", function()
    save_cword()
    move_to_prev_word()
    swap_cword()
  end, { noremap = true, silent = true, desc = "[swap] Swap word leftward" })

  -- Visual mode
  vim.keymap.set("x", "<leader>C", save_visual,
    { desc = "[swap] Save visual selection" })

  vim.keymap.set("x", "<leader>R", swap_visual,
    { desc = "[swap] Swap visual selection with saved selection" })
end

return M
