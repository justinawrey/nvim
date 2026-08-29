-- Background helpers: mutate the running Neovim instance WITHOUT moving the
-- user's focus. Every function here either takes an explicit window/buffer
-- handle, or snapshots + restores the current window and mode around the work.
--
-- Load it at the top of any remote script, asking Neovim to locate this file so
-- that nothing hardcodes an install path:
--   local bg = dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])

local M = {}

-- This file's own directory, derived from the running chunk, so siblings can be
-- loaded without knowing where the skill is installed.
M.dir = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')

-- Load a script sitting next to this one, e.g. M.sibling('state.lua').
function M.sibling(name)
  return dofile(M.dir .. name)
end

-- Pick a window suitable for background work: any normal (non-float, non-special)
-- window in the current tabpage that isn't the excluded one (default: current).
function M.pick_win(exclude)
  exclude = exclude or vim.api.nvim_get_current_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local cfg = vim.api.nvim_win_get_config(w)
    local b = vim.api.nvim_win_get_buf(w)
    if w ~= exclude and cfg.relative == '' and vim.bo[b].buftype == '' then
      return w
    end
  end
  return nil
end

-- Run fn, then put focus AND mode back exactly where they were.
-- Only for work that genuinely cannot be expressed against an explicit handle
-- (`:tabnew`, `:tabclose`, `:mksession`, ...). Everything else: use the API.
function M.keep_focus(fn)
  local win = vim.api.nvim_get_current_win()
  local mode = vim.api.nvim_get_mode().mode
  local insert_like = mode:find('^[it]') ~= nil
  local ok, res = pcall(fn)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    -- Leaving a window drops terminal mode, and stray TermOpen/BufEnter
    -- autocmds can queue a startinsert that would land in the user's window.
    if insert_like then
      vim.cmd('startinsert')
    elseif mode:find('^n') then
      vim.cmd('stopinsert')
    end
  end
  if not ok then
    error(res, 0)
  end
  return res
end

-- Load a file into a buffer. No window, no focus, no side effects.
function M.load(path)
  local buf = vim.fn.bufadd(vim.fn.fnamemodify(path, ':p'))
  vim.fn.bufload(buf)
  return buf
end

-- Show a file in an existing window without focusing that window.
-- Returns win, buf. Falls back to just loading the buffer if there's no target.
function M.show(path, win)
  win = win or M.pick_win()
  local buf = M.load(path)
  if not win then
    return nil, buf
  end
  vim.api.nvim_win_set_buf(win, buf)
  return win, buf
end

-- Open a new split showing `path` (or a scratch buffer) WITHOUT entering it.
-- dir = 'above' | 'below' | 'left' | 'right'. Splits `host` (default: a normal
-- window that isn't the caller's).
function M.split(path, dir, host)
  host = host or M.pick_win() or vim.api.nvim_get_current_win()
  local buf = path and M.load(path) or vim.api.nvim_create_buf(true, false)
  return vim.api.nvim_open_win(buf, false, { split = dir or 'below', win = host }), buf
end

-- Open a new tabpage in the background. Focus stays put. Returns the tabpage handle.
-- There is no enter=false for tabpages, hence keep_focus.
function M.tab(path)
  return M.keep_focus(function()
    vim.cmd('noautocmd tabnew')
    if path then
      vim.cmd.edit(vim.fn.fnamemodify(path, ':p'))
    end
    return vim.api.nvim_get_current_tabpage()
  end)
end

-- Open a terminal in its own new tabpage, in the background. Returns a table of
-- { tab, win, buf, job }. Drive the shell afterwards with M.send(buf, ...).
function M.term_tab(cmd)
  local o = {}
  M.keep_focus(function()
    vim.cmd('noautocmd tabnew')
    vim.cmd(cmd and ('terminal ' .. cmd) or 'terminal')
    o.tab = vim.api.nvim_get_current_tabpage()
    o.win = vim.api.nvim_get_current_win()
    o.buf = vim.api.nvim_get_current_buf()
  end)
  o.job = vim.b[o.buf].terminal_job_id
  return o
end

-- Write straight to a terminal's pty. No focus, no mode juggling, no keystrokes.
-- `submit` appends \r; leave it false to park text in the prompt unsent.
function M.send(buf, text, submit)
  local job = vim.b[buf].terminal_job_id
  assert(job, 'buffer ' .. tostring(buf) .. ' is not a terminal')
  vim.api.nvim_chan_send(job, text .. (submit and '\r' or ''))
  return job
end

-- Read the visible lines of ANY buffer (getline() would need it to be current).
function M.peek(buf, n)
  return table.concat(vim.api.nvim_buf_get_lines(buf, -(n or 40), -1, false), '\n')
end

-- Run an Ex command / lua fn in the context of another window, then come back.
-- Triggers Win/BufEnter autocmds; wrap in M.noauto if that causes flicker.
function M.in_win(win, fn)
  return vim.api.nvim_win_call(win, fn)
end

function M.in_buf(buf, fn)
  return vim.api.nvim_buf_call(buf, fn)
end

-- Run fn with all autocmds suppressed.
function M.noauto(fn)
  local save = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, res = pcall(fn)
  vim.o.eventignore = save
  if not ok then
    error(res, 0)
  end
  return res
end

return M
