local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })

-- Setup once on startup - modern nvim-treesitter handles highlight/indent internally
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if ok then
      configs.setup({
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false, -- was true, double highlight overhead
          disable = function(_, b)
            local ok_stat, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(b))
            if ok_stat and stats and stats.size > 100 * 1024 then return true end
          end,
        },
        indent = { enable = true },
      })
    end
    pcall(require, "nvim-treesitter-textobjects")
  end,
})

-- Fallback: ensure TS starts if not already active (covers non-listed filetypes)
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype == "" and not vim.treesitter.highlighter.active[args.buf] then
      pcall(vim.treesitter.start, args.buf)
    end
  end,
})
