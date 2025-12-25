-- Try and use blink.cmp client capabilties for every LSP.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('config.plug.blink').get_lsp_capabilities({}, false))

vim.lsp.config('*', {
  capabilities = capabilities,
})
