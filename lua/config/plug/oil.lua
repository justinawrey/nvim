local oil = require('oil')
local monitor = require('config.monitor')

-- Fraction of a single monitor the float should take. Oil resolves max_width/max_height
-- against the whole editor (both monitors), so the width is re-resolved in `override`
-- below; max_height still works as-is because monitors are side by side.
local WIDTH = 0.7

oil.setup({
  view_options = {
    show_hidden = true,
  },
  float = {
    max_width = WIDTH,
    max_height = 0.7,
    -- Oil isn't a snacks picker, so it can't hook the shared picker layout; instead it
    -- exposes `override`, which gets the final window config just before the float is
    -- opened (while the current window is still the one '-' was pressed from). Re-anchor
    -- it onto one monitor with the same logic as the pickers and floats -- see
    -- config/monitor.lua.
    override = function(conf)
      local width = math.min(conf.width, math.floor(monitor.width() * WIDTH))
      conf.width = width
      -- -1 to match oil's own border adjustment: the border sits one col left of `col`.
      conf.col = monitor.centered_col(width) - 1
      return conf
    end,
  },
})

return oil
