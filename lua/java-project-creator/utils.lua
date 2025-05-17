-- java-project-creator/utils.lua
-- Utility functions for java-project-creator plugin

local M = {}

-- Helper function to create directories
function M.create_directory(path)
  local cmd = "mkdir -p " .. path
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

-- Helper function to create a file with content
function M.create_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false
  end
  
  file:write(content)
  file:close()
  return true
end

-- Helper function to print status messages
function M.print_status(message, success)
  local prefix = success and "✓" or "✗"
  local color = success and "String" or "Error"
  vim.api.nvim_echo({{prefix .. " " .. message, color}}, true, {})
end

return M
