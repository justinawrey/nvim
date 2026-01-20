local treesitter = require('nvim-treesitter')

-- TODO: I suppose I just install add to this as I go?
-- Table from file type pattern to treesitter lang id.
-- As languages are installed, add them here!
-- Note that reinstalling is a no-op, so we just
-- call install every start up and its fine.
local treesitter_langs = {
  lua = 'lua',
  cs = 'c_sharp',
  yaml = 'yaml',
  html = 'html',
  javascript = 'javascript',
  typescript = 'typescript',
  vue = 'vue',
  markdown = 'markdown',
}

treesitter.install(vim.tbl_values(treesitter_langs))

vim.api.nvim_create_autocmd('FileType', {
  pattern = vim.tbl_keys(treesitter_langs),
  callback = function()
    vim.treesitter.start()
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[0][0].foldmethod = 'expr'

    -- Not having much luck with this with csharp
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

return treesitter
