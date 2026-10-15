vim.lsp.config['go'] = {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork' },
  root_markers = { 'go.work', 'go.mod', '.git' },
}

vim.lsp.enable('go')
