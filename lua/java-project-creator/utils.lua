-- java-project-creator/utils.lua
-- Utility functions for the Java project creator plugin

local M = {}

-- Helper function to create directories with proper handling of spaces
function M.create_directory(dir_path)
  -- Ensure proper directory creation across platforms
  -- Use vim.fn.mkdir for cross-platform compatibility
  if vim.fn.isdirectory(dir_path) == 0 then
    -- The 'p' flag creates parent directories as needed
    local success = vim.fn.mkdir(dir_path, "p")
    if success == 0 then
      M.print_status("Failed to create directory: " .. dir_path, false)
      return false
    end
  end
  return true
end

-- Helper function to create files with proper content
function M.create_file(file_path, content)
  local file = io.open(file_path, "w")
  if file then
    file:write(content)
    file:close()
    return true
  else
    M.print_status("Failed to create file: " .. file_path, false)
    return false
  end
end

-- Helper function to print status messages
function M.print_status(message, success)
  local prefix = success and "✓ " or "✗ "
  local color = success and "String" or "Error"
  vim.api.nvim_echo({ { prefix, color }, { message } }, true, {})
end

return M
