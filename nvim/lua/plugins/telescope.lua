require("telescope").setup({
  defaults = {
    border = true,
    borderchars = {
      prompt = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      results = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
    },
    wrap_results = true,
    layout_strategy = "horizontal",
    layout_config = {
      prompt_position = "top",
    },
    sorting_strategy = "descending",
    winblend = 0,

    mappings = {
      n = {},
    },

    file_ignore_patterns = {
      "build/",
      "%.git/",
      "%.o$",
      "%.a$",
      "%.class$",
      "%.mkv$",
    },
  },

  pickers = {
    colorscheme = {
      enable_preview = true,
    },

    diagnostics = {
      theme = "ivy",
      initial_mode = "normal",

      layout_config = {
        preview_cutoff = 9999,
      },
    },
  },
})

local builtin = require("telescope.builtin")
local themes = require("telescope.themes")

local ivy_base_config = {
  border = true,
  borderchars = {
    prompt = { "─", " ", " ", " ", " ", " ", " ", " " },
    results = { "─", " ", " ", " ", " ", " ", " ", " " },
    preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
  },
}

local function custom_ivy(opts)
  return themes.get_ivy(vim.tbl_deep_extend("force", ivy_base_config, opts or {}))
end

vim.keymap.set("n", "<leader><leader>", function()
  builtin.find_files(custom_ivy())
end, {
  desc = "Lists files in current working directory, respects .gitignore",
})

vim.keymap.set("n", "<leader>fw", function()
  local word = vim.fn.expand("<cword>")
  builtin.grep_string(custom_ivy({ search = word }))
end, {
  desc = "Search current word under cursor",
})

vim.keymap.set("n", "<leader>fW", function()
  local word = vim.fn.expand("<cWORD>")
  builtin.grep_string(custom_ivy({ search = word }))
end, {
  desc = "Search current WORD under cursor",
})

vim.keymap.set("n", "<leader>fg", function()
  builtin.live_grep(custom_ivy())
end, {
  desc = "Live grep in current working directory",
})

vim.keymap.set("n", "<leader>uC", function()
  builtin.colorscheme(custom_ivy())
end, {
  desc = "Try available colorschemes",
})

vim.keymap.set("n", "<leader>fx", function()
  builtin.diagnostics(custom_ivy({
    layout_config = {
      height = 14,
    },
  }))
end, {
  desc = "Lists diagnostics",
})

vim.keymap.set("n", "<leader>fs", function()
  builtin.treesitter(custom_ivy())
end, {
  desc = "Treesitter symbols",
})
