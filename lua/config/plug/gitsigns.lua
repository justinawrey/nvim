local gitsigns = require('gitsigns')

gitsigns.setup({
  attach_to_untracked = true,
  current_line_blame = true,
  -- on_attach = function(bufnr)
  --   vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-1>', '<cmd>lua require"gitsigns".nav_hunk("prev")<CR>', {})
  --   vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-2>', '<cmd>lua require"gitsigns".nav_hunk("next")<CR>', {})
  -- end
})

return gitsigns
