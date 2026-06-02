local M = {}

--- Open a floating-window terminal.
--- opts:
---   cmd      command to run (string|table) -- only used when spawning a new terminal
---   title    window title
---   buf      existing terminal buffer to reuse; if valid, no new process is spawned
---   on_exit  called when the terminal process exits (spawned buffers only)
---   on_close called whenever the floating window closes, for any reason
--- returns { buf = number, win = number, spawned = boolean }
function M.open_floating_win_with_term(opts)
  -- Screen dimensions
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Window size (80%)
  local width = math.floor(columns * 0.98)
  local height = math.floor(lines * 0.9)

  -- Center position
  local col = math.floor((columns - width) / 2)
  local row = math.floor((lines - height) / 2 - 1)

  -- Backdrop
  local backdrop_buf = vim.api.nvim_create_buf(false, true)
  local backdrop_win = vim.api.nvim_open_win(backdrop_buf, false, {
    relative = 'editor',
    width = columns,
    height = lines,
    row = 0,
    col = 0,
    style = 'minimal',
    border = 'none',
    focusable = false,
    zindex = 10,
  })

  -- Darken background
  vim.api.nvim_set_hl(0, 'FloatBackdrop', { bg = '#000000' })
  vim.api.nvim_win_set_option(backdrop_win, 'winhl', 'Normal:FloatBackdrop')
  vim.api.nvim_win_set_option(backdrop_win, 'winblend', 60)

  -- Reuse the given terminal buffer if it's still alive, otherwise spawn a new one.
  local buf = opts.buf
  local spawned = false
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    spawned = true
  end

  -- Open floating window
  local floating_win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = opts.title,
    title_pos = 'center',
  })

  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })

  if spawned then
    vim.fn.termopen(opts.cmd, {
      on_exit = function()
        if opts.on_exit then
          opts.on_exit()
        end
        -- Close whatever window currently shows this terminal. The buffer may have been
        -- reopened in a new window since spawn (e.g. a reused lazygit instance), so we
        -- can't rely on the window handle captured here, or a finished process would
        -- leave a dead float behind.
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end
      end,
    })
  end

  -- IMPORTANT: enter terminal mode
  vim.cmd('startinsert')

  -- Cleanup backdrop (and run on_close) when the floating window closes.
  vim.api.nvim_create_autocmd('WinClosed', {
    once = true,
    pattern = tostring(floating_win),
    callback = function()
      if vim.api.nvim_win_is_valid(backdrop_win) then
        vim.api.nvim_win_close(backdrop_win, true)
      end
      if opts.on_close then
        opts.on_close()
      end
      -- Deliberately NO forced :redraw! here. The original artifact this guarded
      -- against (a z-indexed, winblend'd backdrop leaving stale cells on the
      -- window underneath -- neovim/neovim#14922) is gone on current Neovim:
      -- once the float and backdrop leave the layout, Neovim invalidates and
      -- repaints the covered region on its own, including a :terminal underneath
      -- (verified by capturing the composited screen). A forced clear+repaint is
      -- not just unnecessary -- it re-emits the whole grid for a live :terminal
      -- like Claude Code, which can itself leave it garbled until it next draws.
    end,
  })

  return { buf = buf, win = floating_win, spawned = spawned }
end

function M.open_floating_win(file, title)
  -- Screen dimensions
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Window size (80%)
  local width = math.floor(columns * 0.98)
  local height = math.floor(lines * 0.9)

  -- Center position
  local col = math.floor((columns - width) / 2)
  local row = math.floor((lines - height) / 2 - 1)

  -- Backdrop
  local backdrop_buf = vim.api.nvim_create_buf(false, true)
  local backdrop_win = vim.api.nvim_open_win(backdrop_buf, false, {
    relative = 'editor',
    width = columns,
    height = lines,
    row = 0,
    col = 0,
    style = 'minimal',
    border = 'none',
    focusable = false,
    zindex = 10,
  })

  -- Darken background
  vim.api.nvim_set_hl(0, 'FloatBackdrop', { bg = '#000000' })
  vim.api.nvim_win_set_option(backdrop_win, 'winhl', 'Normal:FloatBackdrop')
  vim.api.nvim_win_set_option(backdrop_win, 'winblend', 60)

  local buf = vim.fn.bufadd(vim.fn.fnamemodify(file, ':p'))
  vim.fn.bufload(buf)

  -- Open floating window
  local floating_win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })

  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })

  -- Cleanup backdrop when main window closes
  vim.api.nvim_create_autocmd('WinClosed', {
    once = true,
    pattern = tostring(floating_win),
    callback = function()
      if vim.api.nvim_win_is_valid(backdrop_win) then
        vim.api.nvim_win_close(backdrop_win, true)
      end
      -- No forced :redraw! (see open_floating_win_with_term): Neovim repaints the
      -- area the blended backdrop covered on its own, and forcing a clear+repaint
      -- can garble a live :terminal underneath instead of helping.
    end,
  })

  return buf
end

return M
