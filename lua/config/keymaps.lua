-- Vert split help.
vim.api.nvim_create_user_command('H', 'vert help <args>', { nargs = '?' })

-- Vert split terminal.
vim.api.nvim_create_user_command('T', 'vert term <args>', { nargs = '?' })

-- Easier exiting insert mode.
vim.keymap.set('i', 'jj', '<Esc>')

-- Jump up and down by chunked amounts.
vim.keymap.set({ 'n', 'v' }, '<S-j>', '8j')
vim.keymap.set({ 'n', 'v' }, '<S-k>', '8k')

-- Lsp format the current buffer.
vim.keymap.set('n', 'ff', vim.lsp.buf.format)

-- Navigate through diagnostics.
vim.keymap.set('n', '1', vim.diagnostic.goto_prev)
vim.keymap.set('n', '2', vim.diagnostic.goto_next)

-- Lsp hover.
vim.keymap.set('n', '<C-n>', vim.lsp.buf.hover)

-- Make vertical splits more/less wide.
vim.keymap.set('n', '<C-9>', '<C-w>6>')
vim.keymap.set('n', '<C-0>', '<C-w>6<')

-- Navigate between panes.
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-j>', '<C-w>j')

-- Clear search highlight.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR><Esc>')

-- Exit terminal mode with jj.
vim.keymap.set('t', 'jj', [[<C-\><C-n>]])

-- Open oil in cwd of active buf.
vim.keymap.set('n', '-', '<CMD>Oil --float<CR>')

vim.keymap.set('n', '<leader><space>', function()
  Snacks.picker.buffers({
    win = {
      input = {
        keys = {
          ['<c-x>'] = false,
          ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)
vim.keymap.set('n', '<leader>saf', function()
  Snacks.picker.files({ hidden = true, ignore = true })
end)
vim.keymap.set('n', '<leader>sf', function()
  Snacks.picker.files()
end)
vim.keymap.set('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end)
vim.keymap.set('n', '<leader>se', function()
  Snacks.picker.explorer()
end)
vim.keymap.set('n', '<leader>sg', function()
  Snacks.picker.grep()
end)
vim.keymap.set('n', '<leader>st', function()
  local function startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
  end

  Snacks.picker({
    title = 'Terminals',
    finder = 'buffers',
    format = 'buffer',
    hidden = false,
    unloaded = true,
    current = true,
    sort_lastused = true,
    filter = {
      filter = function(item)
        return startswith(item.file, 'term://')
      end,
    },
    win = {
      input = {
        keys = {
          ['<c-x>'] = false,
          ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)

-- Open oil in cwd.
vim.keymap.set('n', '<C-->', function()
  require('config.plug.oil').open_float(vim.loop.cwd())
end)
