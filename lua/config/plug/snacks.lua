local snacks = require('snacks')

-- Pickers are centered on a single monitor rather than the whole (two-monitor) editor,
-- using the shared slice logic in config/monitor.lua. Floating windows (scratch terminal,
-- notes popup) go through the same helpers.
local monitor = require('config.monitor')

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

-- Re-anchor a resolved picker layout onto one monitor. Runs for every picker, whatever
-- preset it uses, because it hangs off the global `picker.layout` config.
local function center_on_monitor(layout)
  local box = layout.layout
  -- Split layouts (e.g. the explorer's sidebar preset) dock to an editor edge and have no
  -- free-floating position to move, so leave them alone.
  if not box or (box.position and box.position ~= 'float') then
    return layout
  end

  local monitor_width = monitor.width()

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
  box.col = monitor.centered_col(width, main_win())

  return layout
end

snacks.setup({
  picker = {
    enable = true,
    main = { file = false },
    layout = { config = center_on_monitor },
  },
})

return snacks
