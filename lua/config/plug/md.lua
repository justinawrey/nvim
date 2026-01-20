local md = require('render-markdown')

md.setup({
  html = {
    comment = {
      conceal = false,
    },
  },
})

return md
