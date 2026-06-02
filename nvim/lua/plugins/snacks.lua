require("snacks").setup({
  scratch = {},
  scope = {},
  indent = {
    enabled = false
  },
  statuscolumn = {
    enabled = false,
    right = { "mark", "sign" },
    left = { "fold", "git" },
    folds = {
      open = false,
      git_hl = false,
    },
    git = {
      patterns = { "GitSign", "MiniDiffSign" },
    },
    refresh = 50,
  },
  scroll = {
    animate = {
      duration = { step = 15, total = 250 },
      easing = "linear",
    },
    spamming = 10,
    filter = function(buf)
      return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and
          vim.bo[buf].buftype ~= "terminal"
    end,
  },
  terminal = {
    enabled = true,
    win = { style = "terminal" },
    wo = {}
  },
  bigfile = { enabled = true },
  input = { enabled = true },
  dashboard = {
    enabled = false,
    styles = {
      wo = {
        number = false,
        relativenumber = false,
      }
    },
  },
  notifier = {
    enabled = true,
    timeout = 3000,
    width = { min = 40, max = 0.4 },
    height = { min = 1, max = 0.6 },
    margin = { top = 0, right = 1, bottom = 0 },
    padding = true,
    gap = 0,
    sort = { "level", "added" },
    level = vim.log.levels.TRACE,
    icons = { error = "", warn = "", info = "", debug = "", trace = "" },
    keep = function(notif)
      return vim.fn.getcmdpos() > 0
    end,
    top_down = true,
    date_format = "%R",
    more_format = " ↓ %d lines ",
    refresh = 50,
  },
  quickfile = { enabled = true },
  words = { enabled = true },
  styles = {
    notification = {
      wo = { wrap = true }
    },
    dashboard = {
      wo = {
        number = false,
        relativenumber = false,
      }
    },
  },
})

local map = vim.keymap.set

map("n", "<leader>.",  function() Snacks.scratch()            end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>S",  function() Snacks.scratch.select()     end, { desc = "Select Scratch Buffer" })
map("n", "<leader>un", function() Snacks.notifier.hide()      end, { desc = "Dismiss All Notifications" })
map("n", "<leader>bd", function() Snacks.bufdelete()          end, { desc = "Delete Buffer" })
map("n", "<leader>gg", function() Snacks.lazygit()            end, { desc = "Lazygit" })
map("n", "<leader>gb", function() Snacks.git.blame_line()     end, { desc = "Git Blame Line" })
map("n", "<leader>gB", function() Snacks.gitbrowse()          end, { desc = "Git Browse" })
map("n", "<leader>gf", function() Snacks.lazygit.log_file()   end, { desc = "Lazygit Current File History" })
map("n", "<leader>gl", function() Snacks.lazygit.log()        end, { desc = "Lazygit Log (cwd)" })
map("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File" })
map("n", "<c-/>",      function() Snacks.terminal()           end, { desc = "Toggle Terminal" })
map("n", "<c-_>",      function() Snacks.terminal()           end, { desc = "which_key_ignore" })

map("n", "<leader>N", function()
  Snacks.win({
    file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
    width = 0.6,
    height = 0.6,
    wo = {
      spell = false,
      wrap = false,
      signcolumn = "yes",
      statuscolumn = " ",
      conceallevel = 3,
    },
  })
end, { desc = "Neovim News" })


-- 2. VIMENTER TIMING FIX (Handles toggles and UI layout setup safely)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    _G.dd = function(...)
      Snacks.debug.inspect(...)
    end
    _G.bt = function()
      Snacks.debug.backtrace()
    end
    vim.print = _G.dd

    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.line_number():map("<leader>ul")
    Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
    Snacks.toggle.inlay_hints():map("<leader>uh")
  end,
})


-- 3. LSP PROGRESS NOTIFIER
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value
    if not client or type(value) ~= "table" then
      return
    end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ("[%3d%%] %s%s"):format(
            value.kind == "end" and 100 or value.percentage or 100,
            value.title or "",
            value.message and (" **%s**"):format(value.message) or ""
          ),
          done = value.kind == "end",
        }
        break
      end
    end

    local msg = {}
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(table.concat(msg, "\n"), "info", {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and " "
            or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

map("n", "<leader>do", function()
  Snacks.picker.pickers({
    finder = "meta_pickers",
    format = "text",
    layout = { preset = "ivy" },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          Snacks.picker(item.text, { layout = { preset = "ivy" } })
        end)
      end
    end,
  })
end, { noremap = true, desc = "Open picker for pickers" })
