vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('justin-lsp-attach', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = event.buf })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = event.buf })
    vim.keymap.set('n', '<C-n>', vim.lsp.buf.hover, { buffer = event.buf })
    vim.keymap.set('n', 'gd', function()
      Snacks.picker.lsp_definitions()
    end, { buffer = event.buf })
    vim.keymap.set('n', 'gr', function()
      Snacks.picker.lsp_references()
    end, { buffer = event.buf })

    -- Dont register the format on save for LSPs that arent formatting...
    -- TODO: dont love this here but, whatever.
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    if client.name == 'lua' or client.name == 'roslyn' then
      return
    end

    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('justin-lsp-attach', { clear = false }),
      buffer = event.buf,
      callback = function()
        vim.lsp.buf.format({
          bufnr = event.buf,
          id = client.id,
          timeout_ms = 1000,
        })
      end,
    })
  end,
})
