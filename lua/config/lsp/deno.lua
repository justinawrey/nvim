vim.lsp.config['deno'] = {
  cmd = { 'deno', 'lsp' },
  filetypes = { 'typescript' },
  root_markers = { 'deno.json' },
}

vim.lsp.enable('deno')
