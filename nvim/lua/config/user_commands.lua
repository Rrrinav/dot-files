local M = {}

function M.setup()
  -- Open a floating terminal in project root directory
  -- vim.api.nvim_create_user_command("Fterm", function(opts)
  --   local cmd = opts.args ~= "" and opts.args or "bash"
  --   require("snacks.terminal").open(cmd, {win = { style = "terminal" }})
  -- end, { nargs = "?" })
  --
  -- -- Open floating terminal in the current buffer's directory
  -- vim.api.nvim_create_user_command("Ftermdir", function(opts)
  --   local cmd = opts.args ~= "" and opts.args or "bash"
  --   local cwd = vim.fn.expand("%:p:h") -- Get the current buffer's directory
  --   require("snacks.terminal").open(cmd, { cwd = cwd })
  -- end, { nargs = "?" })

  -- Reload the current buffer with clipboard content
  vim.api.nvim_create_user_command("PasteClipboard", function()
    -- Get the content from the clipboard
    local clipboard_content = vim.fn.getreg("+")

    -- Get the current buffer line count
    local line_count = vim.api.nvim_buf_line_count(0)

    -- Replace the content of the buffer while preserving settings
    vim.api.nvim_buf_set_lines(0, 0, line_count, false, vim.split(clipboard_content, "\n"))
  end, {})

  -- Copy entire buffer
  vim.api.nvim_create_user_command("CBuffer", function()
    vim.cmd("%y+")
  end, {})

  -- Function to generate execution commands based on file type
  local function get_execution_command(filepath, filetype)
    local filename = vim.fn.expand("%:t:r")                  -- Get the file name without extension
    local output = vim.fn.expand("%:p:h") .. "/" .. filename -- Output binary in the same directory as the source file

    if filetype == "lua" then
      return "lua " .. filepath
    elseif filetype == "python" then
      return "python " .. filepath
    elseif filetype == "sh" then
      return "bash " .. filepath
    elseif filetype == "cpp" then
      return "g++ -o " .. output .. " " .. filepath .. " --std=c++23 && " .. output
    elseif filetype == "c" then
      return "gcc -o " .. output .. " " .. filepath .. " && " .. output
    elseif filetype == "rust" then
      return "rustc -o " .. output .. " " .. filepath .. " && " .. output
    elseif filetype == "go" then
      return "go run " .. filepath
    else
      return nil
    end
  end

  -- Create the ExecuteFile command
  vim.api.nvim_create_user_command("ExecuteFile", function()
    local filepath = vim.fn.expand("%:p") -- Get the full path of the current file
    local filetype = vim.bo.filetype      -- Get the file type of the current buffer

    -- Get the command to execute the file
    local cmd = get_execution_command(filepath, filetype)

    if cmd then
      local final_cmd = "Compile " .. cmd;
      vim.cmd(final_cmd);
    else
      -- Notify the user if no execution command is defined for the file type
      vim.notify("No execution command defined for file type: " .. filetype, vim.log.levels.ERROR)
    end
  end, {})
  -- Create user commands
  local function disable_distractions()
    vim.diagnostic.config({ -- https://neovim.io/doc/user/diagnostic.html
      virtual_text = false,
      signs = false,
      underline = false,
    })
    vim.cmd(':lua vim.b.completion = false')
  end

  local function enable_distractions()
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
    })
    vim.cmd(':lua vim.b.completion = true')
  end
  vim.api.nvim_create_user_command('EnableDistractions', enable_distractions, { desc = "Enable distractions" })
  vim.api.nvim_create_user_command('DisableDistractions', disable_distractions, { desc = "Disable distractions" })

  vim.api.nvim_create_user_command('QCompile', function()
    vim.ui.input({
      prompt = "Enter compile command: ",
    }, function(input)
      if input then
        -- Execute the Compile command with the provided input
        vim.cmd('Compile ' .. input)
      end
    end)
  end, {})

  -- Change the current working directory to the directory of the current buffer
  vim.api.nvim_create_user_command('CDHere', function()
    local dir = vim.fn.expand('%:p:h')
    if dir ~= '' then
      vim.cmd('cd ' .. dir)
      print('Changed directory to: ' .. dir)
    else
      print('No file path detected.')
    end
  end, {})

  -- vim.api.nvim_create_user_command('try_ui', function()
  --   vim.ui.input({
  --     prompt = 'Enter your name: ',
  --     default = 'Rinav',
  --     completion = 'customlist',
  --     -- completions = { 'Rinav', 'Ravi', 'Ravi Teja' },
  --   }, function(name)
  --     if name then
  --       print("Hello " .. name)
  --     else
  --       print("No name provided")
  --     end
  --   end)
  -- end, {})
  --
  -- Define a custom :Indent command
  vim.api.nvim_create_user_command("IndentType", function(opts)
    local size = tonumber(opts.fargs[1]) or 4
    local mode = opts.fargs[2] or "spaces"

    vim.opt.shiftwidth = size
    vim.opt.tabstop    = size

    if mode == "tabs" then
      vim.opt.expandtab = false
    else
      vim.opt.expandtab = true
    end

    print("Indent set to " .. size .. " (" .. ( vim.opt.expandtab and "spaces" or "tabs") .. ")")
  end, {
      nargs = "+",     -- at least 1 argument required
      complete = function(_, _, _) return { "tabs", "spaces" } end,
  })

  vim.api.nvim_create_user_command("IndentVal", function(opts)
    local n = tonumber(opts.args)
    if not n or n <= 0 then
      vim.notify("Indent must be a positive number", vim.log.levels.ERROR)
      return
    end

    vim.opt_local.tabstop = n
    vim.opt_local.shiftwidth = n
    vim.opt_local.softtabstop = n
    vim.opt_local.expandtab = true
  end, {
      nargs = 1,
      complete = function()
        return { "2", "4", "8" }
      end,
    })

  -- Compress buffer for LLM input
  vim.api.nvim_create_user_command("CompressLLM", function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get filetype to determine comment string
    local ft = vim.bo[bufnr].filetype
    local comment = vim.bo[bufnr].commentstring:gsub("%%s", "") -- remove %s placeholder

    -- Get all lines
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_lines = {}

    for _, line in ipairs(lines) do
      local l = line

      -- Remove comments (naive: strip from first comment marker)
      if comment ~= "" then
        local pos = l:find(vim.pesc(comment))
        if pos then
          l = l:sub(1, pos - 1)
        end
      end

      -- Trim whitespace
      l = l:gsub("^%s+", ""):gsub("%s+$", "")

      -- Skip empty lines
      if l ~= "" then
        table.insert(new_lines, l)
      end
    end

    -- Replace buffer with compressed version
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  end, {})

end

return M
