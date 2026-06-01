local floating_win = require('config.floating_win')

local M = {}

-- Worktree root (normalized cwd) -> terminal buffer running that worktree's lazygit.
local terms = {}

-- The floating window currently showing lazygit, if any.
local current_win = nil

local function key_for(path)
  return vim.fn.fnamemodify(path, ':p')
end

-- Wrap `lazygit` with the config the integration relies on.
local function build_cmd()
  local config_path = vim.fn.stdpath('config') .. '/lazygit.yml'
  local config_flag = ' --use-config-file=' .. vim.fn.shellescape(config_path)
  return 'lazygit' .. config_flag
end

-- Close the floating window but leave the terminal buffer (and its lazygit process) running.
function M.hide()
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
  end
end

-- Open (or re-show) the lazygit instance for the current worktree.
function M.open()
  local cwd = vim.fn.getcwd()

  -- Only operate inside a git repo; lazygit is useless otherwise. Detect via the .git
  -- entry (a dir in a normal clone, a file in a worktree) anywhere from cwd upward.
  if #vim.fs.find('.git', { upward = true, path = cwd, limit = 1 }) == 0 then
    vim.notify('lazygit: not a git repository (' .. cwd .. ')', vim.log.levels.WARN)
    return
  end

  -- Already visible: just focus it.
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
    vim.cmd('startinsert')
    return
  end

  local key = key_for(cwd)
  local existing = terms[key]
  if existing and not vim.api.nvim_buf_is_valid(existing) then
    existing = nil
  end

  -- Drop the global jj->terminal-normal escape while lazygit is up, so `jj` navigation
  -- in lazygit isn't hijacked. Restored on close.
  pcall(vim.keymap.del, 't', 'jj')

  local opts = {
    title = 'lazygit',
    buf = existing,
    on_close = function()
      pcall(vim.keymap.set, 't', 'jj', [[<C-\><C-n>]])
      current_win = nil
    end,
  }

  if not existing then
    opts.cmd = build_cmd()
    opts.on_exit = function()
      terms[key] = nil
    end
  end

  local result = floating_win.open_floating_win_with_term(opts)
  current_win = result.win

  if result.spawned then
    terms[key] = result.buf
    -- Hide (keep running) with <C-q>. Buffer-local so it survives re-show and only affects lazygit.
    vim.keymap.set('t', '<C-q>', M.hide, { buffer = result.buf })
  end
end

-- Kill the lazygit instance associated with `path` (used when its worktree is closed).
function M.close_for(path)
  local key = key_for(path)
  local buf = terms[key]
  terms[key] = nil
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

return M
