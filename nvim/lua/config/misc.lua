require('custom.llm_context').setup({
  -- Optional: customize settings
  max_files = 50,
  max_file_size = 100000,
})

vim.opt.termguicolors = true

vim.api.nvim_set_hl(0, "TabLineFill", { link = "Normal" })
vim.api.nvim_set_hl(0, "TabLine"    , { link = "Normal" })

vim.g.neovide_scale_factor = 1.0
vim.api.nvim_set_hl(0, '@string.special.symbol.ebnf', { link = '@float' })
local function change_scale(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + delta
end

vim.keymap.set("n", "<C-=>", function() change_scale(0.1) end)  -- Zoom in
vim.keymap.set("n", "<C-->", function() change_scale(-0.1) end) -- Zoom out
vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end) -- Reset zoom

-- Leading/trailing spaces, tabs
vim.o.guifont = "VictorMono Nerd Font:h11"
