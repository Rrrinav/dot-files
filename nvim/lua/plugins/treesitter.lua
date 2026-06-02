local function load_treesitter(buf)
  -- 1. Try to load the packages if they aren't loaded yet
  vim.cmd("packadd nvim-treesitter")
  pcall(vim.cmd, "packadd nvim-treesitter-textobjects")

  -- 2. Attempt to setup (only once)
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if ok then
    -- We define a flag locally to ensure we only run setup() once
    if not vim.g.treesitter_setup_done then
      configs.setup({
        ensure_installed = {
          "c", "cpp", "lua", "vim", "vimdoc",
          "query", "markdown", "markdown_inline"
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
          disable = function(lang, b)
            local ok_stat, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(b))
            if ok_stat and stats and stats.size > 100 * 1024 then return true end
          end,
        },
        indent = { enable = true },
      })
      local ok_to, ts_to = pcall(require, "nvim-treesitter-textobjects")
      if ok_to then ts_to.setup() end
      vim.g.treesitter_setup_done = true
    end

    -- 3. Always ensure Treesitter starts on the specific buffer
    pcall(vim.treesitter.start, buf)
  end
end

-- Hook into both events for 100% coverage
local group = vim.api.nvim_create_augroup("TreesitterCoverage", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile"}, {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype == "" then
      load_treesitter(args.buf)
    end
  end,
})

-- We only use this if the plugin's automatic system fails for a specific buffer.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterFallback", { clear = true }),
  callback = function(args)
    if not vim.treesitter.highlighter.active[args.buf] then
      pcall(vim.treesitter.start, args.buf)
    end
  end,
})
