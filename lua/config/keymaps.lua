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

-- Default term. Splits the current window in half without disturbing other
-- panes -- that comes for free from 'noequalalways' (see config/opts.lua).
vim.api.nvim_create_user_command('T', function(args)
  vim.cmd('Vt ' .. args.args)
end, { nargs = '?' })

-- Scratch terminal: a single, lazily-created terminal shown in a full-screen floating
-- window. <leader>x or :tt opens/re-shows it (reusing the same shell); <C-q> inside it
-- hides the window while leaving the shell running. See config/scratch.lua.
vim.keymap.set('n', '<leader>x', require('config.scratch').open)
vim.api.nvim_create_user_command('Tt', require('config.scratch').open, {})
-- User commands must be capitalized, so :tt can't be one directly. Expand a bare `tt`
-- command line to :Tt -- only when it's the entire command (not e.g. `set tt`).
vim.cmd([[cnoreabbrev <expr> tt (getcmdtype() ==# ':' && getcmdline() ==# 'tt') ? 'Tt' : 'tt']])

-- Easier exiting insert mode.
vim.keymap.set('i', 'jj', '<Esc>')

-- Jump up and down by chunked amounts.
vim.keymap.set({ 'n', 'v' }, '<S-j>', '8j')
vim.keymap.set({ 'n', 'v' }, '<S-k>', '8k')

-- Lsp format the current buffer.
vim.keymap.set('n', 'ff', vim.lsp.buf.format)

-- Toggle format on save.
vim.keymap.set('n', '<leader>fs', function()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify('Format on save: ' .. (vim.g.format_on_save and 'ON' or 'OFF'))
end)

-- Navigate through diagnostics.
vim.keymap.set('n', '1', vim.diagnostic.goto_prev)
vim.keymap.set('n', '2', vim.diagnostic.goto_next)

-- Lsp hover.
vim.keymap.set('n', '<C-n>', vim.lsp.buf.hover)

-- Make vertical splits more/less wide.
-- '(' always moves the divider left, ')' always moves it right,
-- regardless of whether the window is rightmost or not.
vim.keymap.set('n', '<C-9>', function()
  if vim.fn.winnr() == vim.fn.winnr('l') then
    vim.cmd('6wincmd >')
  else
    vim.cmd('6wincmd <')
  end
end)
vim.keymap.set('n', '<C-0>', function()
  if vim.fn.winnr() == vim.fn.winnr('l') then
    vim.cmd('6wincmd <')
  else
    vim.cmd('6wincmd >')
  end
end)

-- Make horizontal splits more/less tall.
-- C-7 always moves the divider down, C-8 always moves it up,
-- regardless of whether the window is bottommost or not.
vim.keymap.set('n', '<C-7>', function()
  if vim.fn.winnr() == vim.fn.winnr('j') then
    vim.cmd('6wincmd -')
  else
    vim.cmd('6wincmd +')
  end
end)
vim.keymap.set('n', '<C-8>', function()
  if vim.fn.winnr() == vim.fn.winnr('j') then
    vim.cmd('6wincmd +')
  else
    vim.cmd('6wincmd -')
  end
end)

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

-- Shift+Enter in nvim's :terminal -> insert a newline in the child app instead of
-- submitting. Ghostty forwards shift+enter as a distinct <S-CR> (kitty keyboard
-- protocol), but nvim's terminal (libvterm) can't re-encode that modifier for the
-- child, so it collapses to a bare CR -- which Claude Code and other readline-style
-- prompts read as "submit". Write the raw bytes ESC+CR straight to the pty instead:
-- that's what Option/Alt+Enter emits, and Claude Code's input parser treats a CR
-- prefixed with ESC as meta+return (a literal newline) with no /terminal-setup needed.
vim.keymap.set('t', '<S-CR>', function()
  local chan = vim.b.terminal_job_id
  if chan then
    vim.api.nvim_chan_send(chan, '\27\r')
  end
end, { desc = 'Terminal: Shift+Enter inserts a newline (e.g. Claude Code)' })

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

-- Name (or rename) the current terminal so it's easy to pick out in the <leader>t
-- picker. Normal-mode only: <leader> is the space key, so a terminal-mode map would
-- clash with typing in the shell -- exit to normal mode (jj) first. Submitting an
-- empty name clears it, reverting the terminal to its auto-derived label.
vim.keymap.set('n', '<leader>n', function()
  if vim.bo.buftype ~= 'terminal' then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  vim.ui.input({ prompt = 'Terminal name: ', default = vim.b[buf].term_name or '' }, function(input)
    if input == nil then
      return
    end
    vim.b[buf].term_name = input ~= '' and input or nil
    vim.notify(input ~= '' and ('Terminal named: ' .. input) or 'Terminal name cleared')
  end)
end)

-- lazygit: one persistent instance per worktree. <leader>lg opens or re-shows it; <C-q>
-- (inside lazygit) hides the window while leaving the process running. See config/lazygit.lua.
vim.keymap.set('n', '<leader>lg', require('config.lazygit').open)

-- notes mappings
vim.keymap.set('n', '<leader>b', function()
  require('config.floating_win').open_floating_win('~/.config/daily/daily.md', 'notes')
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
          -- default <c-q> sends the picker results to the quickfix list; just close instead
          ['<c-q>'] = { 'close', mode = { 'n', 'i' } },
          ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)
vim.keymap.set('n', '<leader>sf', function()
  Snacks.picker.files({
    exclude = picker_ignore,
    hidden = false,
    ignored = false,
    win = {
      input = {
        keys = {
          -- default <c-q> sends the picker results to the quickfix list; just close instead
          ['<c-q>'] = { 'close', mode = { 'n', 'i' } },
          ['<c-h>'] = { 'toggle_hidden', mode = { 'n', 'i' } },
          ['<c-i>'] = { 'toggle_ignored', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)
vim.keymap.set('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end)
vim.keymap.set('n', '<leader>se', function()
  Snacks.picker.explorer({
    exclude = { '*.meta' },
    hidden = true,
    ignored = true,
    layout = { layout = { width = 20, min_width = 20 } },
  })
end)
vim.keymap.set('n', '<leader>sg', function()
  Snacks.picker.grep({
    exclude = picker_ignore,
    hidden = false,
    ignored = false,
    win = {
      input = {
        keys = {
          -- default <c-q> sends the picker results to the quickfix list; just close instead
          ['<c-q>'] = { 'close', mode = { 'n', 'i' } },
          ['<c-h>'] = { 'toggle_hidden', mode = { 'n', 'i' } },
          ['<c-i>'] = { 'toggle_ignored', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)

-- Auto-derived label for a terminal buffer, parsed from its term://{cwd}//{pid}:{cmd}
-- name: "<folder> · <program>" (e.g. "nvim · zsh"). Falls back to 'terminal'.
local function term_auto_label(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return 'terminal'
  end
  local uri = vim.api.nvim_buf_get_name(buf)
  local cwd, cmd = uri:match('^term://(.-)//%d+:(.*)$')
  local parts = {}
  if cwd and cwd ~= '' then
    parts[#parts + 1] = vim.fn.fnamemodify((cwd:gsub('/+$', '')), ':t')
  end
  if cmd and cmd ~= '' then
    parts[#parts + 1] = vim.fn.fnamemodify(vim.split(cmd, ' ')[1], ':t')
  end
  return #parts > 0 and table.concat(parts, ' · ') or 'terminal'
end

-- The explicit user-set name for a terminal buffer (set via <leader>n), or nil if
-- unnamed. Guards against invalid buffer ids: deleting a terminal from the <leader>t
-- picker wipes its buffer, yet the picker may re-render the stale item before its async
-- refresh drops it -- reading vim.b on the dead id would throw "Invalid buffer id".
local function term_name(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local name = vim.b[buf].term_name
  return name ~= '' and name or nil
end

-- Display label for a terminal: the user-given name if any, otherwise the auto-derived
-- label. Shared by the picker formatter and its search transform so the displayed name
-- and the searchable text never drift.
local function term_label(buf)
  return term_name(buf) or term_auto_label(buf)
end

-- Find a window displaying `buf` anywhere across all tabpages (workspaces are just
-- tabpages -- see :Wa/:Wc/:Wcd). Prefers a window in the current tabpage so selecting a
-- terminal that's visible right here never yanks us to another workspace.
local function find_win_with_buf(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

vim.keymap.set('n', '<leader>t', function()
  local function startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
  end

  Snacks.picker({
    title = 'Terminals',
    finder = 'buffers',
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { Snacks.picker.util.align(tostring(item.buf), 3), 'SnacksPickerBufNr' }
      ret[#ret + 1] = { ' ' }
      ret[#ret + 1] = { vim.fn.nr2char(0xf489) .. ' ', 'Special' } -- terminal icon
      ret[#ret + 1] = { term_label(item.buf) }
      local named = term_name(item.buf)
      if named then
        -- keep the folder/command context beside an explicitly named terminal
        ret[#ret + 1] = { '  ' }
        ret[#ret + 1] = { term_auto_label(item.buf), 'SnacksPickerDir' }
      end
      return ret
    end,
    hidden = false,
    unloaded = true,
    current = true,
    sort_lastused = true,
    -- fold the label into the matched text so typing a name filters to it
    transform = function(item)
      item.text = term_label(item.buf) .. ' ' .. (item.text or '')
      return item
    end,
    filter = {
      filter = function(item)
        return startswith(item.file, 'term://')
      end,
    },
    -- If the terminal is already displayed in a window anywhere (any tabpage/workspace),
    -- just focus that window -- switching tabpages if needed -- instead of opening another
    -- copy of it here. Otherwise fall back to the picker's default open behaviour.
    confirm = function(picker, item)
      local win = item and item.buf and vim.api.nvim_buf_is_valid(item.buf) and find_win_with_buf(item.buf)
      if not win then
        -- default behaviour; jump closes the picker itself and needs an action spec
        return Snacks.picker.actions.jump(picker, item, { cmd = 'edit' })
      end
      picker:close()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
        end
      end)
    end,
    -- Same compact styling as the <leader>u URL picker: no preview pane, input on top.
    preview = 'none',
    layout = { preset = 'vscode' },
    win = {
      input = {
        keys = {
          ['<c-x>'] = false,
          -- default <c-q> sends the picker results to the quickfix list; just close instead
          ['<c-q>'] = { 'close', mode = { 'n', 'i' } },
          ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
        },
      },
    },
  })
end)

-- Jump to tab from last Claude Code notification.
-- vim.keymap.set('n', '<leader>d', function()
--   local f = io.open(vim.fn.expand('~/.claude/last_notification_cwd'), 'r')
--   if not f then
--     return
--   end
--   local target_cwd = f:read('*a'):gsub('%s+$', '')
--   f:close()
--
--   if not target_cwd or target_cwd == '' then
--     return
--   end
--
--   for tabnr = 1, vim.fn.tabpagenr('$') do
--     if vim.fn.getcwd(-1, tabnr) == target_cwd then
--       vim.cmd('tabn ' .. tabnr)
--       return
--     end
--   end
-- end)

-- Clear the notification bullet on the current tab.
-- vim.keymap.set('n', '<leader>a', function()
--   local cwd = vim.fn.getcwd(-1, vim.fn.tabpagenr())
--   _G.clear_tab_attention(cwd)
--   _G.stop_tab_spinner(cwd)
-- end)

vim.keymap.set('n', '<leader>wc', '<cmd>Wc<cr>')

-- Open oil in cwd.
vim.keymap.set('n', '<C-->', function()
  require('config.plug.oil').open_float(vim.loop.cwd())
end)
