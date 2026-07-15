local M = {}

-- Open a dimmed, click-through backdrop covering the whole editor, so a floating window
-- in front of it reads as floating rather than blending into the layout behind it. The
-- returned window must be closed when the float it sits behind closes.
local function open_backdrop()
  local backdrop_buf = vim.api.nvim_create_buf(false, true)
  local backdrop_win = vim.api.nvim_open_win(backdrop_buf, false, {
    relative = 'editor',
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = 'minimal',
    border = 'none',
    focusable = false,
    zindex = 10,
  })

  vim.api.nvim_set_hl(0, 'FloatBackdrop', { bg = '#000000' })
  vim.api.nvim_win_set_option(backdrop_win, 'winhl', 'Normal:FloatBackdrop')
  vim.api.nvim_win_set_option(backdrop_win, 'winblend', 60)
  return backdrop_win
end

--- Open a terminal in a floating window.
--- opts:
---   cmd      command to run (string|table) -- only used when spawning a new terminal
---   buf      existing terminal buffer to reuse; if valid, no new process is spawned
---   float    when true, a centered, bordered window over a dimmed backdrop; otherwise
---            a borderless window covering the whole editor (minus the command line)
---   title    window title (float layout only)
---   on_exit  called when the terminal process exits (spawned buffers only)
---   on_close called whenever the window closes, for any reason
--- returns { buf = number, win = number, spawned = boolean }
function M.open_floating_win_with_term(opts)
  -- Geometry depends on the layout: a centered ~full-size float, or a borderless
  -- window covering the whole editor.
  local width, height, col, row, border, backdrop_win
  if opts.float then
    width = math.floor(vim.o.columns * 0.98)
    height = math.floor(vim.o.lines * 0.9)
    col = math.floor((vim.o.columns - width) / 2)
    row = math.floor((vim.o.lines - height) / 2 - 1)
    border = 'rounded'
    backdrop_win = open_backdrop()
  else
    width = vim.o.columns
    height = vim.o.lines - vim.o.cmdheight
    col, row = 0, 0
    border = 'none'
  end

  -- Reuse the given terminal buffer if it's still alive, otherwise spawn a new one.
  local buf = opts.buf
  local spawned = false
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    spawned = true
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = border,
    title = opts.title,
    title_pos = opts.title and 'center' or nil,
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
        -- leave a dead window behind.
        for _, w in ipairs(vim.fn.win_findbuf(buf)) do
          if vim.api.nvim_win_is_valid(w) then
            vim.api.nvim_win_close(w, true)
          end
        end
      end,
    })
  end

  -- IMPORTANT: enter terminal mode
  vim.cmd('startinsert')

  -- Tear down the backdrop and run on_close when the window closes, for any reason.
  vim.api.nvim_create_autocmd('WinClosed', {
    once = true,
    pattern = tostring(win),
    callback = function()
      if backdrop_win and vim.api.nvim_win_is_valid(backdrop_win) then
        vim.api.nvim_win_close(backdrop_win, true)
      end
      if opts.on_close then
        opts.on_close()
      end
    end,
  })

  return { buf = buf, win = win, spawned = spawned }
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

  local backdrop_win = open_backdrop()

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
      -- No forced :redraw! Neovim repaints the area the blended backdrop covered on its
      -- own, and forcing a clear+repaint can garble a live :terminal underneath.
    end,
  })

  return buf
end

return M
