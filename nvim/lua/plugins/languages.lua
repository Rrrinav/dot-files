require("mason").setup()
require("mason-lspconfig").setup({
  -- removed clangd because clang will be installed via dnf and it will cause conflicts with Mason clangd
  -- So I install clangd manually
  ensure_installed = {"lua_ls", "pylsp" },
  automatic_installation = true,
})


vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { library = { vim.env.VIMRUNTIME } },
      completion = { callSnippet = "Replace" },
    },
  },
  on_init = function(client)
    -- lazydev.nvim provides Luv/vim API types; load if available (packs.lua:35)
    pcall(function() require("lazydev").setup({ library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } }) end)
  end,
})
vim.lsp.enable("lua_ls")

vim.lsp.config("pylsp", {
  cmd = { "pylsp" },
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = { enabled = false },
        mccabe = { enabled = true },
        pyflakes = { enabled = true },
        jedi_completion = { include_params = true },
      },
    },
  },
})
vim.lsp.enable("pylsp")

vim.lsp.config("clangd", {
  cmd = {
    "/usr/bin/clangd",
    "-j=6",
    "--query-driver=/usr/bin/clang++,/usr/bin/*clang*",
  },
  offset_encoding = "utf-16",
})
vim.lsp.enable("clangd")


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
    map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
  end,
})

-- Semantic tokens: kept ENABLED for minimal type-aware highlighting
-- (@lsp.type.class/struct/enum -> Type). Previously disabled here, now preserved.
-- If you find LSP colors too noisy, uncomment to disable again:
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client then client.server_capabilities.semanticTokensProvider = nil end
--   end,
-- })
