-- Main autocmd group for general settings
local autocmd_group = vim.api.nvim_create_augroup("CustomSettings", { clear = true })

-- Restore cursor position on file open
vim.api.nvim_create_autocmd("BufReadPost", {
  group = autocmd_group,
  pattern = "*",
  callback = function()
    local line = vim.fn.line([['"]])
    if line > 1 and line <= vim.fn.line("$") then
      vim.cmd('normal! g`"')
    end
  end,
})

-- Set commentstring for C/C++
vim.api.nvim_create_autocmd("FileType", {
  group = autocmd_group,
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.commentstring = "//%s"
  end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = autocmd_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Close help-like buffers with 'q'
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CustomSettings/CloseWithQ", { clear = true }),
  pattern = { "git", "help", "man", "qf", "query", "scratch" },
  desc = "Close with <q>",
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = args.buf, silent = true })
  end,
})

-- Disable LSP on certain file patterns
vim.api.nvim_create_autocmd("LspAttach", {
  group = autocmd_group,
  callback = function(ev)
    _ = ev
    local fname = vim.fn.expand('%:t')
    if fname:match("%.env$") or fname:match("%.example$") or fname:match("^secret%.") or fname:match("%.config$") then
      vim.cmd("LspStop")
      vim.notify("LSP stopped after attachment", vim.log.levels.INFO)
    end
  end,
})

-- Indentation for JS/TS/JSON
vim.api.nvim_create_autocmd("FileType", {
  group = autocmd_group,
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "lua"},
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Map <S-CR> in command-line window to run and stay
vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = vim.api.nvim_create_augroup("CustomSettings/CmdWinStay", { clear = true }),
  desc = "Execute command and stay in the command-line window",
  callback = function(args)
    vim.keymap.set({ "n", "i" }, "<S-CR>", "<CR>q:", { buffer = args.buf, silent = true })
  end,
})

-- Terminal UI adjustments
vim.api.nvim_create_autocmd({ "TermOpen", "TermEnter" }, {
  group = vim.api.nvim_create_augroup("CustomSettings/Terminal", { clear = true }),
  pattern = "*",
  callback = function()
    vim.wo.winbar = ""
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.signcolumn = "no"
    vim.opt_local.cursorcolumn = false
    vim.opt_local.wrap = false
    vim.opt_local.scrolloff = 0
    vim.opt_local.sidescrolloff = 0
    vim.opt_local.buflisted = false
    vim.opt_local.cursorline = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.statuscolumn = ""
  end,
})

-- Auto-save session on exit if a session is open
vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("AutoSaveSession", { clear = true }),
  callback = function()
    local session = vim.v.this_session
    if session ~= "" then
      vim.cmd.mksession({ args = { session }, bang = true })
    end
  end,
})

-- Use custom folds in some file formats.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "txt", "text", "markdown", "md", "org" },
  callback = function()
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevel = 0
  end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "compilation",
    once = true,
    callback = function()
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd("resize " .. height)
    end,
})
