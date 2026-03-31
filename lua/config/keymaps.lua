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
local function open_lazygit(cmd)
  vim.keymap.del('t', 'jj')

  local tmpfile = vim.fn.tempname()
  local env_prefix = 'LAZYGIT_NEW_DIR_FILE=' .. vim.fn.shellescape(tmpfile) .. ' '
  local wrapped_cmd
  if type(cmd) == 'table' then
    wrapped_cmd = env_prefix .. table.concat(cmd, ' ')
  else
    wrapped_cmd = env_prefix .. cmd
  end

  require('config.floating_win').open_floating_win_with_term(wrapped_cmd, 'lazygit', false, function()
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]])

    vim.schedule(function()
      local f = io.open(tmpfile, 'r')
      if f then
        local new_cwd = f:read('*a'):gsub('%s+$', '')
        f:close()
        os.remove(tmpfile)

        local resolve = vim.uv.fs_realpath
        local current_cwd = resolve(vim.fn.getcwd()) or vim.fn.getcwd()
        local resolved_new = resolve(new_cwd) or new_cwd

        if resolved_new ~= '' and resolved_new ~= current_cwd then
          local function cwd_matches(cwd)
            return (resolve(cwd) or cwd) == resolved_new
          end

          local found_tab = nil
          for tabnr = 1, vim.fn.tabpagenr('$') do
            -- Check both tab-level cwd (tcd) and the active window's cwd,
            -- so we also match tabs whose tcd was never set or was cleared.
            if cwd_matches(vim.fn.getcwd(-1, tabnr))
              or cwd_matches(vim.fn.getcwd(vim.fn.tabpagewinnr(tabnr), tabnr))
            then
              found_tab = tabnr
              break
            end
          end

          if found_tab then
            vim.cmd('tabn ' .. found_tab)
          else
            vim.cmd('tabnew')
            vim.cmd('tcd ' .. vim.fn.fnameescape(new_cwd))
          end
        end
      end
    end)
  end)
end

vim.keymap.set('n', '<leader>lg', function()
  open_lazygit('lazygit')
end)

vim.keymap.set('n', '<leader>ll', function()
  open_lazygit('lazygit log')
end)

vim.keymap.set('n', '<leader>ls', function()
  open_lazygit('lazygit status')
end)

vim.keymap.set('n', '<leader>lb', function()
  open_lazygit('lazygit branch')
end)

vim.keymap.set('n', '<leader>lf', function()
  local file = vim.api.nvim_buf_get_name(0)
  open_lazygit({ 'lazygit', '--filter', file })
end)

-- claude mappings
vim.keymap.set('n', '<leader>n', function()
  require('config.floating_win').open_floating_win('~/.config/daily/daily.md', 'notes')
end)

-- notes mappings
vim.keymap.set('n', '<leader>cc', function()
  require('config.floating_win').open_floating_win_with_term('claude', 'claude', true)
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
      preview = {
        wo = {
          number = false,
          signcolumn = 'no',
        },
      },
    },
  })
end)

-- Jump to tab from last Claude Code notification.
vim.keymap.set('n', '<leader>d', function()
  local f = io.open(vim.fn.expand('~/.claude/last_notification_cwd'), 'r')
  if not f then
    return
  end
  local target_cwd = f:read('*a'):gsub('%s+$', '')
  f:close()

  if not target_cwd or target_cwd == '' then
    return
  end

  for tabnr = 1, vim.fn.tabpagenr('$') do
    if vim.fn.getcwd(-1, tabnr) == target_cwd then
      vim.cmd('tabn ' .. tabnr)
      return
    end
  end
end)

-- Clear the notification bullet on the current tab.
vim.keymap.set('n', '<leader>a', function()
  local cwd = vim.fn.getcwd(-1, vim.fn.tabpagenr())
  _G.clear_tab_attention(cwd)
  _G.stop_tab_spinner(cwd)
end)

-- Open oil in cwd.
vim.keymap.set('n', '<C-->', function()
  require('config.plug.oil').open_float(vim.loop.cwd())
end)
