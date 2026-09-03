-- load_configs.lua - ordered, pcall-safe loader
-- Explicit order matters (e.g. mini before dependents). Add new plugins here.
local modules = {
  'plugins.mini',
  'plugins.snacks',
  'plugins.blink',
  'plugins.treesitter',
  'plugins.oil',
  'plugins.multicursor',
  'plugins.render_markdown',
  'plugins.todo_comments',
  'plugins.telescope',
  'plugins.languages',
  'plugins.which_key',
  'plugins.ui',
  'plugins.indent_blankline',
  'plugins.colorizer',
}

for _, m in ipairs(modules) do
  local ok, err = pcall(require, m)
  if not ok then
    vim.notify(("[load_configs] failed to load %s: %s"):format(m, err), vim.log.levels.ERROR)
  end
end

-- Auto-discover any new plugins/*.lua not in the ordered list (warn, don't double-load)
do
  local seen = {}
  for _, m in ipairs(modules) do seen[m] = true end
  local dir = vim.fn.stdpath("config") .. "/lua/plugins"
  local ok, iter = pcall(vim.fs.dir, dir)
  if ok and iter then
    for name, t in iter do
      if t == "file" and name:sub(-4) == ".lua" then
        local mod = "plugins." .. name:sub(1, -5)
        if not seen[mod] then
          local ok2, err2 = pcall(require, mod)
          if not ok2 then
            vim.notify(("[load_configs] auto-load failed %s: %s"):format(mod, err2), vim.log.levels.WARN)
          else
            vim.notify(("[load_configs] auto-loaded %s (add to ordered list)"):format(mod), vim.log.levels.INFO)
          end
        end
      end
    end
  end
end
