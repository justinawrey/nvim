local floating_win = require('config.floating_win')

local M = {}

-- Worktree root (normalized cwd) -> terminal buffer running that worktree's lazygit.
local terms = {}

-- The floating window currently showing lazygit, if any.
local current_win = nil

local function key_for(path)
  return vim.fn.fnamemodify(path, ':p')
end

-- Wrap `lazygit` with the env + config the integration relies on, and hand back the
-- tempfile lazygit writes its exit-directory to (used by follow_cwd on quit).
local function build_cmd()
  local tmpfile = vim.fn.tempname()
  local config_path = vim.fn.stdpath('config') .. '/lazygit.yml'
  local env_prefix = 'LAZYGIT_NEW_DIR_FILE=' .. vim.fn.shellescape(tmpfile) .. ' '
  local config_flag = ' --use-config-file=' .. vim.fn.shellescape(config_path)
  return env_prefix .. 'lazygit' .. config_flag, tmpfile
end

-- When lazygit exits after changing directory, follow it: focus the matching worktree
-- tab if we have one, otherwise open a new one.
local function follow_cwd(tmpfile)
  local f = io.open(tmpfile, 'r')
  if not f then
    return
  end
  local new_cwd = f:read('*a'):gsub('%s+$', '')
  f:close()
  os.remove(tmpfile)

  if new_cwd == '' then
    return
  end

  local tabline = require('config.tabline')
  local has_tab = false
  for _, wt in ipairs(tabline.worktrees) do
    if wt.path == new_cwd then
      has_tab = true
      break
    end
  end

  if has_tab then
    vim.cmd('Wcd ' .. vim.fn.fnameescape(new_cwd))
  else
    vim.cmd('Wa ' .. vim.fn.fnameescape(new_cwd))
  end
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
    local cmd, tmpfile = build_cmd()
    opts.cmd = cmd
    opts.on_exit = function()
      terms[key] = nil
      vim.schedule(function()
        follow_cwd(tmpfile)
      end)
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
