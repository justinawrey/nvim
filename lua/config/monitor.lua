-- Monitor-aware geometry helpers.
--
-- This nvim instance spans two side-by-side monitors, so `vim.o.columns` covers both and
-- anything centered in the editor lands on the bezel. Treat the editor as MONITORS equal
-- horizontal slices and center inside a single slice, picking the slice that holds the
-- window in question (25% or 75% of the way across, for two).
local M = {}

M.MONITORS = 2

-- Width, in columns, of a single monitor slice.
function M.width()
  return math.floor(vim.o.columns / M.MONITORS)
end

-- 0-based index of the monitor an editor column falls on.
function M.of(col, monitor_width)
  monitor_width = monitor_width or M.width()
  return math.min(math.max(math.floor(col / monitor_width), 0), M.MONITORS - 1)
end

-- The monitor to center on: the one holding `win` (defaults to the current window). A
-- window that itself spans both monitors (the common single-window case) has its center
-- on the bezel and so can't pick a side, and falls back to wherever the cursor is sitting.
function M.index(win, monitor_width)
  monitor_width = monitor_width or M.width()
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end
  local left = vim.api.nvim_win_get_position(win)[2]
  local right = left + vim.api.nvim_win_get_width(win) - 1
  if M.of(left, monitor_width) == M.of(right, monitor_width) then
    return M.of(left, monitor_width)
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local screen = vim.fn.screenpos(win, cursor[1], cursor[2] + 1)
  local col = (screen and screen.col and screen.col > 0) and screen.col - 1
    or left + math.floor((right - left) / 2)
  return M.of(col, monitor_width)
end

-- Absolute column for a window of `width` columns centered on the monitor holding `win`.
function M.centered_col(width, win)
  local monitor_width = M.width()
  return M.index(win, monitor_width) * monitor_width + math.floor((monitor_width - width) / 2)
end

-- Width/col for a float taking `fraction` of one monitor, centered on the monitor holding
-- `win` (defaults to the current window).
function M.centered_width_col(fraction, win)
  local monitor_width = M.width()
  local width = math.max(1, math.floor(monitor_width * fraction))
  return width, M.centered_col(width, win)
end

return M
