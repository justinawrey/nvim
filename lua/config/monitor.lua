-- Monitor-aware geometry helpers.
--
-- This nvim instance often spans several side-by-side monitors, so `vim.o.columns` covers
-- all of them and anything centered in the editor lands on a bezel. Treat the editor as
-- `count()` equal horizontal slices and center inside a single slice, picking the slice
-- that holds the window in question (25% or 75% of the way across, for two).
--
-- The count is set by hand with `:Monitors N` -- there's no reliable, cheap way to ask
-- macOS how many displays the Ghostty window is straddling, and the answer only changes
-- when the window is deliberately moved or resized. The value is written to a state file
-- so it survives restarts and applies to every nvim instance started afterwards.
local M = {}

local STATE_FILE = vim.fs.joinpath(vim.fn.stdpath('state'), 'monitors')
local DEFAULT = 2
local MAX = 4

local count

local function load()
  local fd = io.open(STATE_FILE, 'r')
  if not fd then
    return DEFAULT
  end
  local contents = fd:read('*l')
  fd:close()
  local n = tonumber(contents or '')
  if not n or n < 1 or n > MAX or n ~= math.floor(n) then
    return DEFAULT
  end
  return n
end

local function save(n)
  local fd = io.open(STATE_FILE, 'w')
  if not fd then
    return
  end
  fd:write(tostring(n), '\n')
  fd:close()
end

-- Number of monitors the editor is spread across.
function M.count()
  if not count then
    count = load()
  end
  return count
end

-- Set the monitor count for this session, and persist it for future ones.
function M.set_count(n)
  count = n
  save(n)
end

-- Width, in columns, of a single monitor slice.
function M.width()
  return math.floor(vim.o.columns / M.count())
end

-- 0-based index of the monitor an editor column falls on.
function M.of(col, monitor_width)
  monitor_width = monitor_width or M.width()
  return math.min(math.max(math.floor(col / monitor_width), 0), M.count() - 1)
end

-- The monitor to center on: the one holding `win` (defaults to the current window). A
-- window that itself spans several monitors (the common single-window case) has its center
-- on a bezel and so can't pick a side, and falls back to wherever the cursor is sitting.
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

-- `:Monitors` prints the current count, `:Monitors N` sets it. Only affects floats opened
-- afterwards, which is every float, since geometry is resolved at open time.
vim.api.nvim_create_user_command('Monitors', function(opts)
  if opts.args == '' then
    vim.notify('monitors: ' .. M.count())
    return
  end
  local n = tonumber(opts.args)
  if not n or n < 1 or n > MAX or n ~= math.floor(n) then
    vim.notify('Monitors: expected an integer 1-' .. MAX, vim.log.levels.ERROR)
    return
  end
  M.set_count(n)
  vim.notify('monitors: ' .. n)
end, {
  nargs = '?',
  complete = function()
    local items = {}
    for i = 1, MAX do
      items[i] = tostring(i)
    end
    return items
  end,
})

return M
