local floating_win = require('config.floating_win')

local M = {}

-- The single scratch terminal buffer. Lazily created on the first open and reused
-- (along with its running shell) on every subsequent open.
local scratch_buf = nil

-- The window currently showing the scratch terminal, if any.
local current_win = nil

-- Close the window but leave the scratch terminal buffer (and its shell) running.
function M.hide()
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
  end
end

-- Open (or re-show) the single scratch terminal in a full-screen floating window.
-- The terminal is created on the first call; every later call reuses the same buffer
-- and the shell still running inside it.
function M.open()
  -- Already visible: just focus it.
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
    vim.cmd('startinsert')
    return
  end

  local existing = scratch_buf
  if existing and not vim.api.nvim_buf_is_valid(existing) then
    existing = nil
  end

  local opts = {
    buf = existing,
    float = true,
    title = ' scratch ',
    on_close = function()
      current_win = nil
    end,
  }

  if not existing then
    opts.cmd = vim.o.shell
    opts.on_exit = function()
      scratch_buf = nil
    end
  end

  local result = floating_win.open_floating_win_with_term(opts)
  current_win = result.win

  if result.spawned then
    scratch_buf = result.buf
    -- Label it 'scratch' so it stands out in the <leader>t terminal picker
    -- (see config/keymaps.lua term_name/term_label).
    vim.b[result.buf].term_name = 'scratch'
    -- Hide (keeping the shell running) with <C-q>. Mapped in both terminal and normal
    -- mode: unlike lazygit, the scratch terminal keeps the global jj escape, so you may
    -- press <C-q> from either mode. Buffer-local, so it survives a re-show.
    vim.keymap.set({ 't', 'n' }, '<C-q>', M.hide, { buffer = result.buf })
  end
end

return M
