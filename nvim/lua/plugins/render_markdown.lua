vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("LazyRenderMarkdown", { clear = true }),
  pattern = { "markdown", "markdown.mdx", "md" },
  callback = function()
    require("render-markdown").setup({
      enabled = false,
      -- Headings
      heading = {
        enabled = true,
        sign = false,
        settext = false,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
        -- icons = { "󰎤  ", "󰎧  ", "󰎪  ", "󰎭  ", "󰎱  ", "󰎳  " },
      },

      -- Code blocks
      code = {
        enabled = true,
        sign = false,
        style = "full", -- "full" | "language"
        position = "left",
      },

      -- Lists
      bullet = {
        enabled = true,
        icons = { "•", "◦", "▪", "▫" },
      },

      -- Checkboxes
      checkbox = {
        enabled   = true,
        unchecked = { icon = "󰄱 " },
        checked   = { icon = "󰄵 " },
        custom    = {
          todo = { raw = "[>]", rendered = "󰥔 ", highlight = "Todo" },
        },
      },

      -- Quotes
      quote = {
        enabled = true,
        icon = "▍",
      },

      -- Tables
      table = {
        enabled = true,
        style = "full",
      },

      -- Links
      link = {
        enabled = true,
        image = "󰥶 ",
        hyperlink = "󰌹 ",
      },

      -- Rendering behavior
      render_modes = { "n" },
      anti_conceal = { enabled = true },
    })
  end,
  once = true,
})
