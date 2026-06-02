vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("LazyIBL", { clear = true }),
  callback = function()
    require("ibl").setup({
      scope = { enabled = false }
    })

    vim.api.nvim_set_hl(0, "IblTabIndent", { fg = "#44545a", nocombine = true })

    local function update_ibl_color()
      if not vim.bo.expandtab then
        vim.opt_local.winhighlight = "IblIndent:IblTabIndent,@ibl.indent.char.1:IblTabIndent"
      else
        vim.opt_local.winhighlight = ""
      end
    end

    local gid = vim.api.nvim_create_augroup("IBLTabColor", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "OptionSet" }, {
      group = gid,
      pattern = "*",
      callback = update_ibl_color,
    })

    update_ibl_color()
  end,
  once = true,
})
