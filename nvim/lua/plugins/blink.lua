require('blink.cmp').setup({
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 400,
      window = {
        border = "rounded",
        winhighlight = "FloatBorder:FloatBorder"
      },
    },
    keyword = { range = "full" },
    list = { selection = { preselect = true, auto_insert = false } },
    menu = {
      auto_show = false,
      -- border = "rounded",
      winhighlight = "FloatBorder:FloatBorder",
      draw = {
        columns = {
          { "kind_icon",         "label", gap = 1 },
          { "label_description", "kind",  gap = 1 }
        },
        -- treesitter = { "lsp" }
      }
    },
    ghost_text = {
      enabled = function()
        return require("blink.cmp").is_visible()
      end,
    },
  },
  sources = {
    default = { "snippets", "lsp", "path", "buffer", "omni" },     -- Changed from default to enabled, removed luasnip
    providers = {
      copilot = {
        name = "copilot",
        module = "blink-cmp-copilot",
        score_offset = 100,
        async = true,
        transform_items = function(_, items)
          local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
          local kind_idx = #CompletionItemKind + 1
          CompletionItemKind[kind_idx] = "Copilot"
          for _, item in ipairs(items) do
            item.kind = kind_idx
          end
          return items
        end,
      },
    },
  },
  signature = {
    enabled = true,
    window = { border = "single" }
  },
  appearance = {
    kind_icons = require('../icons').autocomplete,
  },
  keymap = {
    preset        = 'none',
    ['<C-space>'] = { 'show' },
    ['<C-e>']     = { 'hide', 'fallback' },
    ['<CR>']      = { 'accept', 'fallback' },
    ['<C-y>']     = { 'accept', 'fallback' },
    ['<Up>']      = { 'select_prev', 'fallback' },
    ['<Down>']    = { 'select_next', 'fallback' },
    ['<C-p>']     = { 'select_prev', 'fallback' },
    ['<C-n>']     = { 'select_next', 'fallback' },
    ['<C-b>']     = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>']     = { 'scroll_documentation_down', 'fallback' },
    ['<Tab>']     = { 'snippet_forward', 'select_next', 'fallback' },
    ['<S-Tab>']   = { 'snippet_backward', 'select_prev', 'fallback' },
  },
  cmdline = {
  },
  enabled = function()
    -- disable in comments (Treesitter first)
    local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
    if ok then
      local node = ts_utils.get_node_at_cursor()
      while node do
        if node:type() == "comment" then
          return false
        end
        node = node:parent()
      end
    end

    -- fallback: syntax group check
    local pos = vim.api.nvim_win_get_cursor(0)
    local line, col = pos[1], pos[2]
    local syn_id = vim.fn.synID(line, col + 1, 1)
    local syn_name = vim.fn.synIDattr(syn_id, "name")
    if syn_name:match("Comment") then
      return false
    end

    -- default blink.cmp conditions
    return vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
  end,
})
