vim.lsp.config['lua'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
    },
  },
  on_attach = function(client)
    -- Stylua LSP will handle formatting.
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

vim.lsp.config['stylua'] = {
  cmd = { 'stylua', '--lsp' },
  filetypes = { 'lua' },
  root_markers = { '.stylua.toml' },
}

-- For lua, we use lua-language-server for everything except formatting.
-- We use stylua running in LSP mode (stylua --lsp) for formatting,
-- since it is noticeably much snappier.
vim.lsp.enable('lua')
vim.lsp.enable('stylua')
