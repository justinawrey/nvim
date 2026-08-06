local snacks = require('snacks')

-- This nvim instance spans two side-by-side monitors, so `vim.o.columns` covers both and
-- a picker centered in the editor lands on the bezel. Treat the editor as MONITORS equal
-- horizontal slices and center the picker inside a single slice, picking the slice that
-- holds the window the picker was opened from (25% or 75% of the way across, for two).
local MONITORS = 2

-- The window the picker acts on. Resolved the same way the picker itself does it (see
-- picker.core.main), so the slice we pick matches the buffer the picker will operate on
-- rather than, say, a float that happens to be focused. Called before any picker window
-- exists, so the current window is still the user's.
local function main_win()
  local ok, win = pcall(function()
    return require('snacks.picker.core.main').new({ file = false }):get()
  end)
  if ok and win and win ~= 0 and vim.api.nvim_win_is_valid(win) then
    return win
  end
  return vim.api.nvim_get_current_win()
end

-- 0-based index of the monitor an editor column falls on.
local function monitor_of(col, monitor_width)
  return math.min(math.max(math.floor(col / monitor_width), 0), MONITORS - 1)
end

-- The monitor to center on: the one holding the main window. A window that itself spans
-- both monitors (the common single-window case) has its center on the bezel and so can't
-- pick a side, and falls back to wherever the cursor is sitting.
local function monitor_index(monitor_width)
  local win = main_win()
  local left = vim.api.nvim_win_get_position(win)[2]
  local right = left + vim.api.nvim_win_get_width(win) - 1
  if monitor_of(left, monitor_width) == monitor_of(right, monitor_width) then
    return monitor_of(left, monitor_width)
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local screen = vim.fn.screenpos(win, cursor[1], cursor[2] + 1)
  local col = (screen and screen.col and screen.col > 0) and screen.col - 1
    or left + math.floor((right - left) / 2)
  return monitor_of(col, monitor_width)
end

-- Re-anchor a resolved picker layout onto one monitor. Runs for every picker, whatever
-- preset it uses, because it hangs off the global `picker.layout` config.
local function center_on_monitor(layout)
  local box = layout.layout
  -- Split layouts (e.g. the explorer's sidebar preset) dock to an editor edge and have no
  -- free-floating position to move, so leave them alone.
  if not box or (box.position and box.position ~= 'float') then
    return layout
  end

  local monitor_width = math.floor(vim.o.columns / MONITORS)

  -- Snacks resolves fractional/zero widths against the parent (the full editor), so
  -- re-resolve against one monitor and hand back an absolute width instead.
  local width = box.width or 0
  if width == 0 then
    width = monitor_width
  elseif width < 1 then
    width = math.floor(monitor_width * width)
  end
  -- min_width/max_width are applied after ours, so clamp them too or a preset like
  -- `default` (min_width = 120) would blow straight back over the bezel.
  width = math.max(width, math.min(box.min_width or 0, monitor_width))
  width = math.min(width, box.max_width or monitor_width, monitor_width)

  box.width = width
  box.min_width = math.min(box.min_width or width, monitor_width)
  box.max_width = math.min(box.max_width or monitor_width, monitor_width)
  box.col = monitor_index(monitor_width) * monitor_width + math.floor((monitor_width - width) / 2)

  return layout
end

snacks.setup({
  picker = {
    enable = true,
    main = { file = false },
    layout = { config = center_on_monitor },
  },
  lazygit = {
    enable = true,
    -- configure = true,
    -- config = {
    --   git = {
    --     paging = {
    --       pager = 'delta --dark --paging=never',
    --     },
    --   },
    -- },
  },
})

return snacks
