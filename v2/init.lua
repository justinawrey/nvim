-- Get line numbers.
vim.opt.number = true

-- Use spaces instead of tabs, and make them not huge.
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Easier exiting insert mode.
vim.keymap.set('i', 'jj', '<Esc>')

-- Navigate the default popup boxes easier.
vim.keymap.set({ 'i', 'c' }, '<C-j>', '<C-n>')
vim.keymap.set({ 'i', 'c' }, '<C-k>', '<C-p>')

-- Jump up and down by chunked amounts.
vim.keymap.set('n', '<S-j>', '8j')
vim.keymap.set('n', '<S-k>', '8k')

-- Lsp format the current buffer.
vim.keymap.set('n', 'ff', vim.lsp.buf.format)

-- Navigate through diagnostics.
vim.keymap.set('n', '1', vim.diagnostic.goto_prev)
vim.keymap.set('n', '2', vim.diagnostic.goto_next)

-- Lsp hover.
vim.keymap.set('n', '<C-n>', vim.lsp.buf.hover)

-- Virtual text diagnostics to the right of problematic lines.
vim.diagnostic.config({
  virtual_text = true
})

-- Make the autocomplete usable, otherwise the first menu item
-- is auto-selected which fucking sucks.
vim.cmd('set completeopt+=noselect')

-- Put the absolute path of the current file in the winbar.
vim.cmd('set winbar=%F')

-- Rounded diagnostic window borders that are easier to see.
vim.o.winborder = 'rounded'

-- Lua language server config.
vim.lsp.config['luals'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { 'init.lua' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
      },
    }
  }
}

-- Enable lua language server.
vim.lsp.enable('luals')

-- Setup native autocomplete using the attached LSPs trigger character.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})
