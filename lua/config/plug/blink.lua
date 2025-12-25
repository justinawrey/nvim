local blink = require('blink.cmp')

blink.setup({
  keymap = {
    preset = 'enter',
    -- Disable default next/prev navigation.
    ['<C-n>'] = false,
    ['<C-p>'] = false,
    ['<C-j>'] = { 'select_next', 'fallback' },
    ['<C-k>'] = { 'select_prev', 'fallback' },
  },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 0 },
    ghost_text = { enabled = true },
  },
})

return blink
