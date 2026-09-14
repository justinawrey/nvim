local nonels = require('null-ls')

local prettier_configs = {
  '.prettierrc',
  '.prettierrc.json',
  '.prettierrc.json5',
  '.prettierrc.yml',
  '.prettierrc.yaml',
  '.prettierrc.toml',
  '.prettierrc.js',
  '.prettierrc.cjs',
  '.prettierrc.mjs',
  'prettier.config.js',
  'prettier.config.cjs',
  'prettier.config.mjs',
}

nonels.setup({
  sources = {
    nonels.builtins.formatting.prettier.with({
      runtime_condition = function(params)
        return vim.fs.root(params.bufnr, prettier_configs) ~= nil
      end,
    }),
  },
})

return nonels
