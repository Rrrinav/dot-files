-- LLM Context Collector for Neovim
-- Save as ~/.config/nvim/lua/llm_context.lua

local M = {}

-- Configuration
M.config = {
  max_file_size = 100000, -- Max file size in bytes (100KB)
  max_files = 50,
  ignore_patterns = {
    "%.git/", "node_modules/", "%.pyc$", "__pycache__/",
    "%.o$", "%.so$", "%.a$", "build/", "dist/",
    "%.min%.js$", "%.bundle%.js$", "%.lock$"
  },
  priority_files = {
    "README.md", "README.rst", "README.txt",
    "package.json", "setup.py", "Cargo.toml",
    "go.mod", "pom.xml", "build.gradle"
  },
  include_extensions = {
    ".lua" , ".py"   , ".js" , ".ts" , ".tsx"  , ".jsx",
    ".go"  , ".rs"   , ".c"  , ".cpp", ".h"    , ".hpp",
    ".java", ".rb"   , ".php", ".cs" , ".swift",
    ".kt"  , ".scala", ".md" , ".txt", ".yaml" , ".yml",
    ".json", ".toml" , ".xml", ".sh" , ".bash" ,
    ".phos", ".cppm" , ".ixx", ".cc" , ".cxx"
  }
}

-- Get project root directory
local function get_project_root()
  local root_patterns = { ".git", "package.json", "setup.py", "Cargo.toml", "go.mod", ".gitignore" }

  for _, pattern in ipairs(root_patterns) do
    local root = vim.fn.finddir(pattern, ".;")
    if root ~= "" then
      return vim.fn.fnamemodify(root, ":h")
    end

    local file = vim.fn.findfile(pattern, ".;")
    if file ~= "" then
      return vim.fn.fnamemodify(file, ":h")
    end
  end

  return vim.fn.getcwd()
end

-- Check if file should be ignored
local function should_ignore(filepath)
  for _, pattern in ipairs(M.config.ignore_patterns) do
    if filepath:match(pattern) then
      return true
    end
  end
  return false
end

-- Check if file has valid extension
local function has_valid_extension(filepath)
  for _, ext in ipairs(M.config.include_extensions) do
    if filepath:match(ext .. "$") then
      return true
    end
  end
  return false
end

-- Get file size
local function get_file_size(filepath)
  local uv = vim.loop or vim.uv
  local stat = uv.fs_stat(filepath)
  return stat and stat.size or 0
end

-- Read file content
local function read_file(filepath)
  local file = io.open(filepath, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

-- Get directory tree structure
local function get_tree_structure(dir, prefix, max_depth, current_depth)
  if current_depth > (max_depth or 3) then return "" end

  local output = ""
  local uv = vim.loop or vim.uv
  local handle = uv.fs_scandir(dir)
  if not handle then return output end

  local entries = {}
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    local path = dir .. "/" .. name
    if not should_ignore(path) then
      table.insert(entries, { name = name, type = type, path = path })
    end
  end

  table.sort(entries, function(a, b) return a.name < b.name end)

  for i, entry in ipairs(entries) do
    local is_last = i == #entries
    local connector = is_last and "└── " or "├── "
    local next_prefix = prefix .. (is_last and "    " or "│   ")

    output = output .. prefix .. connector .. entry.name .. "\n"

    if entry.type == "directory" then
      output = output .. get_tree_structure(entry.path, next_prefix, max_depth, current_depth + 1)
    end
  end

  return output
end

-- Collect all relevant files
local function collect_files(root_dir)
  local files = {}
  local priority_files = {}

  local function scan_dir(dir)
    if #files + #priority_files >= M.config.max_files then return end

    local uv = vim.loop or vim.uv
    local handle = uv.fs_scandir(dir)
    if not handle then return end

    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name then break end

      local path = dir .. "/" .. name
      -- Calculate relative path more safely
      local rel_path
      if path:sub(1, #root_dir) == root_dir then
        rel_path = path:sub(#root_dir + 2) -- +2 to skip the leading slash
      else
        rel_path = path
      end

      if not should_ignore(path) then -- Check full path, not relative
        if type == "directory" then
          scan_dir(path)
        elseif type == "file" then
          local size = get_file_size(path)
          if size > 0 and size < M.config.max_file_size and has_valid_extension(name) then
            local is_priority = false
            for _, priority in ipairs(M.config.priority_files) do
              if name == priority then
                is_priority = true
                break
              end
            end

            if is_priority then
              table.insert(priority_files, { path = path, rel_path = rel_path, size = size })
            else
              table.insert(files, { path = path, rel_path = rel_path, size = size })
            end
          end
        end
      end
    end
  end

  scan_dir(root_dir)

  -- Combine priority files first, then regular files
  local all_files = {}
  for _, f in ipairs(priority_files) do
    table.insert(all_files, f)
  end
  for _, f in ipairs(files) do
    if #all_files < M.config.max_files then
      table.insert(all_files, f)
    end
  end

  return all_files
end

-- Generate context output
function M.generate_context(opts)
  opts = opts or {}
  local root_dir = opts.root_dir or get_project_root()
  local include_tree = opts.include_tree ~= false
  local include_current = opts.include_current ~= false

  local output = "# Project Context\n\n"
  output = output .. "Project Root: " .. root_dir .. "\n\n"

  -- Add directory tree
  if include_tree then
    output = output .. "## Directory Structure\n\n```\n"
    output = output .. vim.fn.fnamemodify(root_dir, ":t") .. "/\n"
    output = output .. get_tree_structure(root_dir, "", 3, 1)
    output = output .. "```\n\n"
  end

  -- Add current file context
  if include_current then
    local current_file = vim.fn.expand("%:p")
    if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
      local rel_path = current_file:sub(#root_dir + 2)
      output = output .. "## Current File\n\n"
      output = output .. "File: " .. rel_path .. "\n\n"
      output = output .. "```" .. vim.bo.filetype .. "\n"
      output = output .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
      output = output .. "\n```\n\n"
    end
  end

  -- Collect and add relevant files
  output = output .. "## Project Files\n\n"
  local files = collect_files(root_dir)

  for _, file_info in ipairs(files) do
    local content = read_file(file_info.path)
    if content then
      output = output .. "### " .. file_info.rel_path .. "\n\n"
      output = output .. "```\n" .. content .. "\n```\n\n"
    end
  end

  return output
end

-- Copy context to clipboard
function M.copy_to_clipboard(root_dir)
  local context = M.generate_context({ root_dir = root_dir })
  vim.fn.setreg("+", context)
  print("Context copied to clipboard! (" .. #context .. " characters)")
end

-- Save context to file
function M.save_to_file(filepath, root_dir)
  filepath = filepath or vim.fn.input("Save context to: ", "llm_context.md")
  if filepath == "" then return end

  local context = M.generate_context({ root_dir = root_dir })
  local file = io.open(filepath, "w")
  if file then
    file:write(context)
    file:close()
    print("Context saved to " .. filepath)
  else
    print("Error: Could not save file")
  end
end

-- Open context in new buffer
function M.open_in_buffer(root_dir)
  local context = M.generate_context({ root_dir = root_dir })

  -- Create new buffer
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()

  -- Set buffer options
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_buf_set_name(buf, "LLM Context")

  -- Insert content
  local lines = vim.split(context, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  print("Context opened in new buffer")
end

-- Setup function
function M.setup(user_config)
  -- Merge user config with defaults
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end

  -- Create commands
  vim.api.nvim_create_user_command("LLMContext", function(opts)
    local root_dir = nil
    if opts.args ~= "" then
      -- Expand and resolve the provided directory path
      root_dir = vim.fn.fnamemodify(vim.fn.expand(opts.args), ":p")
      -- Remove trailing slash
      root_dir = root_dir:gsub("/$", "")

      -- Verify it's a valid directory
      if vim.fn.isdirectory(root_dir) == 0 then
        print("Error: Not a valid directory: " .. root_dir)
        return
      end
    end
    M.open_in_buffer(root_dir)
  end, { nargs = "?", complete = "dir" })

  vim.api.nvim_create_user_command("LLMContextCopy", function(opts)
    local root_dir = nil
    if opts.args ~= "" then
      root_dir = vim.fn.fnamemodify(vim.fn.expand(opts.args), ":p")
      root_dir = root_dir:gsub("/$", "")

      if vim.fn.isdirectory(root_dir) == 0 then
        print("Error: Not a valid directory: " .. root_dir)
        return
      end
    end
    M.copy_to_clipboard(root_dir)
  end, { nargs = "?", complete = "dir" })

  vim.api.nvim_create_user_command("LLMContextSave", function(opts)
    local args = vim.split(opts.args, "%s+")
    local filepath = args[1] ~= "" and args[1] or nil
    local root_dir = nil

    if args[2] and args[2] ~= "" then
      root_dir = vim.fn.fnamemodify(vim.fn.expand(args[2]), ":p")
      root_dir = root_dir:gsub("/$", "")

      if vim.fn.isdirectory(root_dir) == 0 then
        print("Error: Not a valid directory: " .. root_dir)
        return
      end
    end

    M.save_to_file(filepath, root_dir)
  end, { nargs = "?", complete = "file" })
end

return M
