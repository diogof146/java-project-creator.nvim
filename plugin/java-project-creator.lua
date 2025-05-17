-- Plugin loading script for java-project-creator
-- This file ensures the plugin is properly loaded by Neovim

if vim.fn.has('nvim-0.7.0') == 0 then
  vim.api.nvim_echo({{
    'java-project-creator.nvim requires Neovim >= 0.7.0',
    'WarningMsg'
  }}, true, {})
  return
end

-- This prevents the plugin from being loaded multiple times
if vim.g.loaded_java_project_creator == 1 then
  return
end
vim.g.loaded_java_project_creator = 1
