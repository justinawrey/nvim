local gitsigns = require('gitsigns')

gitsigns.setup({
  attach_to_untracked = true,
  current_line_blame = true
})

return gitsigns
