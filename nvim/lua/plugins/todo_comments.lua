vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("LazyTodoComments", { clear = true }),
  callback = function()
    require("todo-comments").setup({
      keywords = {
        DOUBT = { icon = " ", color = "#ff9911" },
      },
    })
  end,
  once = true,
})
