local map = function(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

vim.opt.mouse = "a"

-- FIND / SEARCH
map("n", "-", "<Cmd>Oil<Cr>", { desc = "Open oil" })

map("n", "<leader>ff", function() require("oil").open_float() end, { desc = "Find: oil float" })
map("n", "<leader>fo", function() require("oil").open_float(vim.fn.getcwd()) end, { desc = "Find: oil float (cwd)" })
map("n", "<leader>fe", function() Snacks.explorer() end, { desc = "Find: file explorer" })

-- buffer picker lives here — it's finding a buffer, not operating on one
map("n", "<leader>fb", function()
  Snacks.picker.buffers({ layout = { preset = "ivy" } })
end, { desc = "Find: open buffers" })

map("n", "<leader>bd", function()
  if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then
    vim.cmd("bd")
  else
    vim.notify("Can't close the last buffer!")
  end
end, { desc = "Buffer: close safely" })

map("n", "<leader>bo", function()
  local current = vim.fn.bufnr("%")
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if buf.bufnr ~= current then vim.cmd("bd " .. buf.bufnr) end
  end
end, { desc = "Buffer: close others" })

map("n", "<leader>bs", "<Cmd>ArenaOpen<cr>", { desc = "Buffer: arena frecency" })

-- <leader>t → tab page operations only
-- gt / gT: next/prev (native Vim, no conflict with blink or multicursor)

map("n", "gt", "<cmd>tabnext<cr>", { desc = "Tab: next" })
map("n", "gT", "<cmd>tabprevious<cr>", { desc = "Tab: prev" })
-- ──────────────────────────────────────────────────────────────────── TERMINAL ──
-- <leader>T → terminal launchers
-- <C-/> Snacks.terminal toggle stays in snacks.lua (it's a Snacks concern)

map("n", "<leader>Tv", "<Cmd>vsplit | term<cr>", { desc = "Terminal: vertical split" })
map("n", "<leader>Tf", "<Cmd>Fterm<cr>", { desc = "Terminal: floating (Fterm)" })
map("t", "<C-/>", "<C-\\><C-n>:q<cr>", { desc = "Terminal: exit insert mode" })

-- ────────────────────────────────────────────────────────────────── CODE / LSP ──
-- <leader>c → code actions, formatting, refactoring
-- NOTE: <leader>ca (code action) is set in languages.lua on LspAttach so it's
-- buffer-local and takes priority. The completion toggle has been moved to <leader>uc.

map("n", "<leader>cf", "<cmd>lua vim.lsp.buf.format()<cr>",
  { nowait = true, desc = "Code: format buffer" })

map("v", "<leader>cf", function()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  vim.lsp.buf.format({
    range = { ["start"] = { s[2], s[3] - 1 }, ["end"] = { e[2], e[3] } },
  })
end, { desc = "Code: format selection" })

-- cR → rename file (Snacks) — already in snacks.lua, listed here for reference
-- gd, K, <leader>ca → set in languages.lua LspAttach (buffer-local)

-- ──────────────────────────────────────────────────────────── UI / TOGGLES ──
-- <leader>u → visual/editor toggles
-- Most Snacks toggles (spell, wrap, numbers, treesitter…) are set in snacks.lua.
-- Completion toggle lives here because it's a UI-layer concern, not an LSP one.
map("n", "<leader>uca", "<cmd>lua vim.b.completion = false<cr>", { desc = "UI: disable completion" })
map("n", "<leader>uce", "<cmd>lua vim.b.completion = true<cr>", { desc = "UI: enable completion" })

-- colorscheme picker → already in telescope.lua as <leader>uC

-- ──────────────────────────────────────────────────────────────── DIAGNOSTICS ──
-- <leader>x → diagnostic inspection and quickfix

map("n", "<leader>xf", function()
  vim.diagnostic.open_float(nil, { border = "rounded" })
end, { desc = "Diagnostic: open float" })

map("n", "<leader>xx", vim.diagnostic.setqflist, { desc = "Diagnostic: to quickfix" })
map("n", "<leader>xt", "<cmd>TodoQuickFix<cr>", { desc = "Diagnostic: list todos" })

map("n", "<leader>xh", function()
  vim.diagnostic.config({ virtual_text = false, signs = false, underline = false })
end, { desc = "Diagnostic: hide" })

map("n", "<leader>xs", function()
  vim.diagnostic.config({ virtual_text = true, signs = true, underline = true })
end, { desc = "Diagnostic: show" })

-- ─────────────────────────────────────────────────────────────────── WINDOWS ──
-- Direct <C-hjkl> navigation — no leader, no group pollution

map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Window: vertical split" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Window: horizontal split" })
map("n", "<C-h>", "<C-w>h", { desc = "Window: go left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window: go down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window: go up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window: go right" })

-- ─────────────────────────────────────────────────────────────────── MOVEMENT ──

map("x", "<A-j>", ":move '>+1<cr>gv=gv", { desc = "Line: move down (visual)" })
map("x", "<A-k>", ":move '<-2<cr>gv=gv", { desc = "Line: move up (visual)" })
map("n", "<A-j>", ":m .+1<cr>==", { desc = "Line: move down" })
map("n", "<A-k>", ":m .-2<cr>==", { desc = "Line: move up" })

map("n", "n", "nzzzv", { desc = "Search: next (centered)" })
map("n", "N", "Nzzzv", { desc = "Search: prev (centered)" })

map("v", "<", "<gv", { desc = "Indent: decrease (stay in visual)" })
map("v", ">", ">gv", { desc = "Indent: increase (stay in visual)" })

-- ──────────────────────────────────────────────────────────────────────── MISC ──

map("n", "<A-t>", "<leader>Cw<leader>R",
  { desc = "Swap: words" })

map("n", "<leader>Q",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gIc<Left><Left><Left><Left>]],
  { desc = "Edit: replace word under cursor" })

map({ "i", "s", "n" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape: clear hlsearch" })

-- ─────────────────────────────────────────────── FILETYPE: compilation buffer ──

vim.api.nvim_create_autocmd("FileType", {
  pattern = "compilation",
  callback = function(ev)
    map("n", "r", "<cmd>Recompile<cr>", { buffer = ev.buf, desc = "Compile: rerun" })
    map("n", "]", "<cmd>NextError<cr>", { buffer = ev.buf, desc = "Compile: next error" })
    map("n", "[", "<cmd>PrevError<cr>", { buffer = ev.buf, desc = "Compile: prev error" })
  end,
})
