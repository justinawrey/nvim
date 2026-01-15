local snacks = require('snacks')

snacks.setup({
  picker = {
    enable = true,
  },
  lazygit = {
    enable = true,
    configure = true,
    config = {
      git = {
        paging = {
          pager = 'delta --dark --paging=never',
        },
      },
    },
  },
})

return snacks
