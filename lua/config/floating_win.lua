local M = {}

local persistent_terms = {}

function M.open_floating_win_with_term(cmd, title, persist, on_close)
  -- Screen dimensions
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Window size (80%)
  local width = math.floor(columns * 0.9)
  local height = math.floor(lines * 0.85)

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

  local buf
  local spawn = false
  if persist then
    buf = persistent_terms[cmd]

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      persistent_terms[cmd] = buf
      spawn = true
    end
  else
    buf = vim.api.nvim_create_buf(false, true)
    spawn = true
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
    title = title,
    title_pos = 'center',
  })

  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })

  if spawn then
    vim.fn.termopen(cmd, {
      on_exit = function()
        if vim.api.nvim_win_is_valid(floating_win) then
          on_close()
          vim.api.nvim_win_close(floating_win, true)
        end
      end,
    })
  end

  -- IMPORTANT: enter terminal mode
  vim.cmd('startinsert')
  --
  -- Cleanup backdrop when main window closes
  vim.api.nvim_create_autocmd('WinClosed', {
    once = true,
    pattern = tostring(floating_win),
    callback = function()
      if vim.api.nvim_win_is_valid(backdrop_win) then
        vim.api.nvim_win_close(backdrop_win, true)
      end
    end,
  })

  return buf
end

function M.open_floating_win(file, title)
  -- Screen dimensions
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Window size (80%)
  local width = math.floor(columns * 0.9)
  local height = math.floor(lines * 0.85)

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
    end,
  })

  return buf
end

return M
