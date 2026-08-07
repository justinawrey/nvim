-- Get a version of cwd that uses ~ instead of the expanded name.
function _G.cwd_short()
  local cwd = vim.loop.cwd()
  local home = vim.loop.os_homedir()

  -- replace home path with ~
  cwd = cwd:gsub('^' .. home, '~')
  return cwd
end

-- Current time, e.g. 02:05 PM.
function _G.statusline_time()
  return os.date('%I:%M %p')
end

vim.opt.statusline = '%#StatusLineNoBold#[%{v:lua.cwd_short()}]'
  .. '%='
  .. '%#StatusLineNoBold#%{v:lua.statusline_time()} '

-- Redraw the statusline periodically so the clock stays current.
local timer = vim.loop.new_timer()
timer:start(
  0,
  10000,
  vim.schedule_wrap(function()
    vim.cmd('redrawstatus')
  end)
)
