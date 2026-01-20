vim.lsp.config['md'] = {
  cmd = { 'marksman', 'server' },
  filetypes = { 'markdown', 'markdown.mdx' },
  root_markers = { '.marksman.toml', '.git' },
}

vim.lsp.enable('md')
