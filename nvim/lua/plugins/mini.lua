require("mini.cursorword").setup();
require("mini.hipatterns").setup();

require("mini.align").setup({
  mappings = {
    start              = "ma",
    start_with_preview = "mA",
  },
})

require("mini.surround").setup({
  custom_surroundings = nil,

  highlight_duration = 500,

  mappings = {
    add            = '<leader>msa', -- Add surrounding in Normal and Visual modes
    delete         = '<leader>msd', -- Delete surrounding
    find           = '<leader>msf', -- Find surrounding (to the right)
    find_left      = '<leader>msF', -- Find surrounding (to the left)
    highlight      = '<leader>msh', -- Highlight surrounding
    replace        = '<leader>msr', -- Replace surrounding
    update_n_lines = '<leader>msn', -- Update `n_lines`

    suffix_last    = 'l',           -- Suffix to search with "prev" method
    suffix_next    = 'n',           -- Suffix to search with "next" method
  },

  -- Number of lines within which surrounding is searched
  n_lines = 20,

  -- Whether to respect selection type:
  -- - Place surroundings on separate lines in linewise mode.
  -- - Place surroundings on each line in blockwise mode.
  respect_selection_type = false,

  -- How to search for surrounding (first inside current line, then inside
  -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
  -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
  -- see `:h MiniSurround.config`.
  search_method = 'cover',

  -- Whether to disable showing non-error feedback
  -- This also affects (purely informational) helper messages shown after
  -- idle time if user input is required.
  silent = false,
})
