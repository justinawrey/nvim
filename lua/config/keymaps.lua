-- Vert split help.
vim.api.nvim_create_user_command('H', 'vert help <args>', { nargs = '?' })

-- Vert split terminal.
vim.api.nvim_create_user_command('Vt', function(args)
  local cmd = 'vert term '
  for _, v in pairs(args.fargs) do
    cmd = cmd .. v
  end

  vim.cmd(cmd)
  vim.cmd('start')
end, { nargs = '?' })

-- Horz split terminal
vim.api.nvim_create_user_command('Ht', function(args)
  local cmd = 'hor term '
  for _, v in pairs(args.fargs) do
    cmd = cmd .. v
  end

  vim.cmd(cmd)
  vim.cmd('start')
end, { nargs = '?' })

-- Default term
vim.api.nvim_create_user_command('T', function(args)
  vim.cmd('Vt ' .. args.args)
end, { nargs = '?' })

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

-- Navigate between tabs.
vim.keymap.set('n', '<C-1>', '<CMD>tabn 1<CR>')
vim.keymap.set('n', '<C-2>', '<CMD>tabn 2<CR>')
vim.keymap.set('n', '<C-3>', '<CMD>tabn 3<CR>')
vim.keymap.set('n', '<C-4>', '<CMD>tabn 4<CR>')
vim.keymap.set('n', '<C-5>', '<CMD>tabn 5<CR>')
vim.keymap.set('n', '<C-6>', '<CMD>tabn 6<CR>')

-- Clear search highlight.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR><Esc>')

-- Exit terminal mode with jj.
vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
vim.keymap.set('t', '<C-j>', '<Down>')
vim.keymap.set('t', '<C-k>', '<Up>')

-- Terminal-normal-mode <C-d>: exit shell + close buffer
vim.keymap.set('n', '<C-d>', function()
  -- Only act in terminal buffers
  if vim.bo.buftype ~= 'terminal' then
    return
  end

  -- Enter terminal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('i<C-d>', true, false, true), 'n', false)

  -- Close the buffer after shell exits
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(0) then
      vim.cmd('bd!')
    end
  end)
end, { silent = true })

-- lazygit mappings. we're doing a bit of a hack here -- removing and adding global mappings
-- when going in and out of lazygit via these keybindings. there is probably a more robust
-- way but you know what? idc
vim.keymap.set('n', '<leader>lg', function()
  vim.keymap.del('t', 'jj')

  require('config.floating_win').open_floating_win('lazygit', 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
  end)
end)

vim.keymap.set('n', '<leader>ll', function()
  vim.keymap.del('t', 'jj')

  require('config.floating_win').open_floating_win('lazygit log', 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
  end)
end)

vim.keymap.set('n', '<leader>ls', function()
  vim.keymap.del('t', 'jj')

  require('config.floating_win').open_floating_win('lazygit status', 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
  end)
end)

vim.keymap.set('n', '<leader>lb', function()
  vim.keymap.del('t', 'jj')

  require('config.floating_win').open_floating_win('lazygit branch', 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
  end)
end)

vim.keymap.set('n', '<leader>lf', function()
  vim.keymap.del('t', 'jj')

  local file = vim.api.nvim_buf_get_name(0)
  require('config.floating_win').open_floating_win({ 'lazygit', '--filter', file }, 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
  end)
end)

-- claude mappings
vim.keymap.set('n', '<leader>cc', function()
  require('config.floating_win').open_floating_win('claude', 'claude', true)
end)

-- Open oil in cwd of active buf.
vim.keymap.set('n', '-', '<CMD>Oil --float<CR>')

-- Send a recompilation signal to a server
-- that may or may not be listening.  Who knows!
vim.keymap.set('n', '<leader>rr', '<CMD>UnityRecompile<CR>')

local picker_ignore = {
  '*.meta',
  '*.blend',
  '*.colors',
  '*.controller',
  '*.png',
  '*.asset',
  '*.dll',
  '*.ttf',
  '*.TTF',
  '*.otf',
  '*.OTF',
  '*.inputactions',
  '*.mat',
  '*.prefab',
  '*.XML',
  '*.unity',
  '*.shadersubgraph',
  '*.shadergraph',
  '*.shader',
  '*.jpg',
  '*.jpeg',
  '*.renderTexture',
  '*.anim',
}

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
  Snacks.picker.files({
    exclude = picker_ignore,
  })
end)
vim.keymap.set('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end)
vim.keymap.set('n', '<leader>se', function()
  Snacks.picker.explorer({
    exclude = { '*.meta' },
  })
end)
vim.keymap.set('n', '<leader>sg', function()
  Snacks.picker.grep({
    exclude = picker_ignore,
  })
end)
vim.keymap.set('n', '<leader>sag', function()
  Snacks.picker.grep({ hidden = true, ignore = true })
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
