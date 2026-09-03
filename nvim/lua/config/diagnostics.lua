-- config/diagnostics.lua - extracted from basic_gui.lua
-- Centralizes vim.diagnostic.config and the virtual_text <-> virtual_lines toggle.

local M = {}

local use_virtual_text = true

local function base_config()
  return {
    update_in_insert = false,
    severity_sort = true,
    signs = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    virtual_text = {
      virt_text_pos = "eol_right_align",
      current_line = true,
      source = "if_many",
      prefix = "",
      severity = { min = vim.diagnostic.severity.WARN },
    },
    underline = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
  }
end

function M.setup()
  vim.diagnostic.config(base_config())

  local function swap_diagnostics()
    use_virtual_text = not use_virtual_text
    if use_virtual_text then
      vim.diagnostic.config({
        virtual_text = {
          virt_text_pos = "eol_right_align",
          current_line = true,
          source = "if_many",
          severity = { min = vim.diagnostic.severity.WARN },
        },
        virtual_lines = false,
      })
      vim.notify("Diagnostics: using virtual_text", vim.log.levels.INFO)
    else
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = {
          current_line = true,
          source = "if_many",
          severity = { min = vim.diagnostic.severity.WARN },
        },
      })
      vim.notify("Diagnostics: using virtual_lines", vim.log.levels.INFO)
    end
  end

  vim.keymap.set("n", "<leader>xv", swap_diagnostics, { desc = "Toggle virtual_text / virtual_lines" })
  vim.keymap.set("n", "<leader>xh", function()
    vim.diagnostic.config({ virtual_text = false, signs = false, underline = false })
  end, { desc = "Diagnostic: hide" })
  vim.keymap.set("n", "<leader>xs", function()
    vim.diagnostic.config({ virtual_text = true, signs = true, underline = true })
  end, { desc = "Diagnostic: show" })
end

-- Helpers for user_commands.lua Disable/Enable distractions
function M.disable()
  vim.diagnostic.config({ virtual_text = false, signs = false, underline = false })
end

function M.enable()
  vim.diagnostic.config({ virtual_text = true, signs = true, underline = true })
end

return M
