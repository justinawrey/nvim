local snacks = require('snacks')

snacks.setup({
  picker = { enabled = true },
  keys = {
    { "<leader><space>", function() Snacks.picker.smart() end },
  }
})

return snacks
