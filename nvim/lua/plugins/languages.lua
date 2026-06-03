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
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
    },
  },
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
    "clangd",
    "-j=6"
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

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    client.server_capabilities.semanticTokensProvider = nil
  end,
})
