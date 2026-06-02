require('oil').setup({
  default_file_explorer = true,
  columns = {
    "icon",
    "permissions",
    "size",
  },
  delete_to_trash = true,
  watch_for_changes = true,
  keymaps = {
    ["q"] = { "actions.close", mode = "n" },
  },
  view_options = {
    is_hidden_file = function(name, bufnr)
      if name == ".env" or name == ".gitignore" then
        return false
      end
      local m = name:match("^%.")
      return m ~= nil
    end,
  },
  float = {
    padding = 4,
    max_width = 0,
    max_height = 0,
    border = "single",
    win_options = {
      winblend = 10,
    },
    -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
    get_win_title = nil,
    -- preview_split: Split direction: "auto", "left", "right", "above", "below".
    preview_split = "auto",
    -- This is the config that will be passed to nvim_open_win.
    -- Change values here to customize the layout
    override = function(conf)
      return conf
    end,
  },
})
