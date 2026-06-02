local mc = require("multicursor-nvim")
mc.setup()
local set = vim.keymap.set

-- ─s Add cursors ────────────────────────────────────────────────────────
set({ "n", "v" }, "<A-Up>", function() mc.lineAddCursor(-1) end, { desc = "mc: add cursor above" })
set({ "n", "v" }, "<A-Down>", function() mc.lineAddCursor(1) end, { desc = "mc: add cursor below" })
set({ "n", "v" }, "<A-Right>", function() mc.addCursor("w") end, { desc = "mc: add cursor next word" })
set({ "n", "v" }, "<A-Left>", function() mc.addCursor("b") end, { desc = "mc: add cursor prev word" })

-- ── Skip (no cursor, just move) ────────────────────────────────────────
set({ "n", "v" }, "<A-S-Up>", function() mc.lineSkipCursor(-1) end, { desc = "mc: skip cursor above" })
set({ "n", "v" }, "<A-S-Down>", function() mc.lineSkipCursor(1) end, { desc = "mc: skip cursor below" })
set({ "n", "v" }, "<A-S-Right>", function() mc.skipCursor("w") end, { desc = "mc: skip next word" })
set({ "n", "v" }, "<A-S-Left>", function() mc.skipCursor("b") end, { desc = "mc: skip prev word" })

-- ── Match word under cursor ────────────────────────────────────────────
set({ "n", "v" }, "<A-n>", function() mc.matchAddCursor(1) end, { desc = "mc: add cursor next match" })
set({ "n", "v" }, "<A-p>", function() mc.matchAddCursor(-1) end, { desc = "mc: add cursor prev match" })
set({ "n", "v" }, "<A-S-n>", function() mc.matchSkipCursor(1) end, { desc = "mc: skip next match" })
set({ "n", "v" }, "<A-S-p>", function() mc.matchSkipCursor(-1) end, { desc = "mc: skip prev match" })
set({ "n", "v" }, "<A-a>", mc.matchAllAddCursors, { desc = "mc: add cursor all matches" })

-- ── Navigate between cursors ───────────────────────────────────────────
set({ "n", "v" }, "<A-[>", mc.prevCursor, { desc = "mc: prev cursor" })
set({ "n", "v" }, "<A-]>", mc.nextCursor, { desc = "mc: next cursor" })

-- ── Cursor operations ──────────────────────────────────────────────────
set({ "n", "v" }, "<A-x>", mc.deleteCursor, { desc = "mc: delete cursor" })
set({ "n", "v" }, "<A-d>", mc.duplicateCursors, { desc = "mc: duplicate cursors" })
set({ "n", "v" }, "<A-r>", mc.restoreCursors, { desc = "mc: restore cursors" })
set({ "n", "v" }, "<A-=>", mc.alignCursors, { desc = "mc: align cursors" })

-- ── Visual mode ────────────────────────────────────────────────────────
set("v", "<A-s>", mc.splitCursors, { desc = "mc: split selections" })
set("v", "<A-m>", mc.matchCursors, { desc = "mc: match within selection" })
set("v", "<A-i>", mc.insertVisual, { desc = "mc: insert at start" })
set("v", "<A-e>", mc.appendVisual, { desc = "mc: append at end" })
set("v", "<A-t>", function() mc.transposeCursors(1) end, { desc = "mc: transpose forward" })
set("v", "<A-T>", function() mc.transposeCursors(-1) end, { desc = "mc: transpose backward" })

-- ── Mouse ──────────────────────────────────────────────────────────────
set("n", "<C-LeftMouse>", mc.handleMouse, { desc = "mc: click add cursor" })

-- ── Jumplist ───────────────────────────────────────────────────────────
set({ "v", "n" }, "<C-i>", mc.jumpForward, { desc = "mc: jump forward" })
set({ "v", "n" }, "<C-o>", mc.jumpBackward, { desc = "mc: jump backward" })

-- ── Mode management ────────────────────────────────────────────────────
-- <A-q>: toggle between disabled/enabled cursors (freeze/unfreeze)
set({ "n", "v" }, "<A-q>", function()
  if mc.cursorsEnabled() then
    mc.disableCursors()
    vim.notify("multicursor: frozen", vim.log.levels.INFO)
  else
    mc.enableCursors()
    vim.notify("multicursor: unfrozen", vim.log.levels.INFO)
  end
end, { desc = "mc: toggle freeze" })

-- :MClear — clear all extra cursors and return to normal editing
vim.api.nvim_create_user_command("MClear", function()
  if mc.hasCursors() then
    mc.clearCursors()
    vim.notify("multicursor: cleared", vim.log.levels.INFO)
  else
    vim.notify("multicursor: no cursors active", vim.log.levels.WARN)
  end
end, { desc = "Clear all multicursors" })

-- <Esc><Esc>: double escape to clear — feels natural coming from terminal habits
set("n", "<Esc><Esc>", function()
  if not mc.cursorsEnabled() then
    mc.enableCursors()
  elseif mc.hasCursors() then
    mc.clearCursors()
  end
end, { desc = "mc: clear or re-enable cursors" })
