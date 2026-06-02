-- which_key.lua

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("LazyWhichKey", { clear = true }),
  callback = function()
    require("which-key").setup({
      preset = "helix",
      win = {
        border = "single",
        wo = { winblend = 50 },
      },
      spec = {
        -- ── Ungrouped ───────────────────────────────────────────────────────
        { "<leader>.",  desc = "Toggle Scratch Buffer" },
        { "<leader>S",  desc = "Select Scratch Buffer" },
        { "<leader>Q",  desc = "Replace word under cursor" },
        { "<leader>N",  desc = "Neovim News" },
        { "<leader>-",  desc = "Horizontal split" },
        { "<leader>|",  desc = "Vertical split" },
        { "<leader><leader>", desc = "Find files (Telescope)" },

        -- ── Find / Search ───────────────────────────────────────────────────
        { "<leader>f",  group = "Find / Search" },
        { "<leader>ff", desc = "Oil: float" },
        { "<leader>fo", desc = "Oil: float (cwd)" },
        { "<leader>fe", desc = "File explorer (Snacks)" },
        { "<leader>fb", desc = "Open buffers (Snacks)" },
        { "<leader>fw", desc = "Grep word under cursor" },
        { "<leader>fW", desc = "Grep WORD under cursor" },
        { "<leader>fg", desc = "Live grep" },
        { "<leader>fs", desc = "Treesitter symbols" },
        { "<leader>fx", desc = "Diagnostics list" },

        -- ── Buffers ─────────────────────────────────────────────────────────
        { "<leader>b",  group = "Buffers" },
        { "<leader>bd", desc = "Close buffer safely" },
        { "<leader>bo", desc = "Close other buffers" },
        { "<leader>bs", desc = "Arena frecency selector" },

        -- ── Tabs ────────────────────────────────────────────────────────────
        { "<leader>t",  group = "Tabs" },
        { "<leader>tn", desc = "New tab" },
        { "<leader>tc", desc = "Close tab" },
        { "<leader>to", desc = "Close other tabs" },
        { "<leader>t<", desc = "Move tab left" },
        { "<leader>t>", desc = "Move tab right" },

        -- ── Terminal ────────────────────────────────────────────────────────
        { "<leader>T",  group = "Terminal" },
        { "<leader>Tv", desc = "Vertical split terminal" },
        { "<leader>Tf", desc = "Floating terminal (Fterm)" },

        -- ── Code / LSP ──────────────────────────────────────────────────────
        { "<leader>c",  group = "Code / LSP" },
        { "<leader>ca", desc = "Code action" },
        { "<leader>cf", desc = "Format buffer / selection" },
        { "<leader>cR", desc = "Rename file (Snacks)" },

        -- ── UI / Toggles ────────────────────────────────────────────────────
        { "<leader>u",  group = "UI / Toggles" },
        { "<leader>uC", desc = "Colorscheme picker" },
        { "<leader>un", desc = "Dismiss notifications" },
        { "<leader>us", desc = "Toggle spelling" },
        { "<leader>uw", desc = "Toggle wrap" },
        { "<leader>uL", desc = "Toggle relative numbers" },
        { "<leader>ud", desc = "Toggle diagnostics" },
        { "<leader>ul", desc = "Toggle line numbers" },
        { "<leader>uc", group = "Completion" },
        { "<leader>uca", desc = "Disable completion" },
        { "<leader>uce", desc = "Enable completion" },
        { "<leader>uT", desc = "Toggle Treesitter" },
        { "<leader>ub", desc = "Toggle background" },
        { "<leader>uh", desc = "Toggle inlay hints" },

        -- ── Git ─────────────────────────────────────────────────────────────
        { "<leader>g",  group = "Git" },
        { "<leader>gg", desc = "Lazygit" },
        { "<leader>gb", desc = "Git blame line" },
        { "<leader>gB", desc = "Git browse" },
        { "<leader>gf", desc = "Lazygit file history" },
        { "<leader>gl", desc = "Lazygit log (cwd)" },

        -- ── Mini ────────────────────────────────────────────────────────────
        { "<leader>m",  group = "Mini", icon = "󱀧 " },
        { "<leader>ms", group = "Surround", icon = "󱀧 " },
        { "<leader>msa", desc = "Add surrounding" },
        { "<leader>msd", desc = "Delete surrounding" },
        { "<leader>msf", desc = "Find surrounding (right)" },
        { "<leader>msF", desc = "Find surrounding (left)" },
        { "<leader>msh", desc = "Highlight surrounding" },
        { "<leader>msr", desc = "Replace surrounding" },
        { "<leader>msn", desc = "Update n_lines" },

        -- ── Diagnostics ─────────────────────────────────────────────────────
        { "<leader>x",  group = "Diagnostics", icon = "" },
        { "<leader>xx", desc = "Diagnostics to quickfix" },
        { "<leader>xf", desc = "Open diagnostic float" },
        { "<leader>xh", desc = "Hide diagnostics" },
        { "<leader>xs", desc = "Show diagnostics" },
        { "<leader>xt", desc = "List todos (quickfix)" },

        -- ── Debug / Meta ────────────────────────────────────────────────────
        { "<leader>d",  group = "Debug / Meta" },
        { "<leader>do", desc = "Meta pickers (Snacks)" },
      },
    })
  end,
  once = true,
})
