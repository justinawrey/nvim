-- Get a version of cwd that uses ~ instead of the expanded name.
function _G.cwd_short()
  local cwd = vim.loop.cwd()
  local home = vim.loop.os_homedir()

  -- replace home path with ~
  cwd = cwd:gsub('^' .. home, '~')
  return cwd
end

vim.opt.statusline =
  '%#StatusLineNoBold#[%{v:lua.cwd_short()}]'
