-- Add the config path to package.path so I can relatively
-- require like: require('plug.some-plug').
-- Feels weird, idk if this is the right, but whatever, it works.
-- Might act weirdly if init files are somewhere other than
-- the standard config paths but... w/e
package.path = vim.fn.stdpath('config') .. '/?.lua;' .. package.path

-- Space leader.
vim.keymap.set('n', '<space>', '<nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Snacks, but only for the picker.
require('plug.snacks')

-- Gitsigns, for nice info in the left sidebar and change counts.
require('plug.gitsigns')

-- Oil, for file editing like a buffer.
require('plug.oil')

-- Get line numbers.
vim.opt.number = true

-- Use spaces instead of tabs, and make them not huge.
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Force vertical split panes to split to the right.
vim.opt.splitright = true

-- Force horizontal split panes to split below.
vim.opt.splitbelow = true

-- Rounded diagnostic window borders that are easier to see.
vim.opt.winborder = 'rounded'

-- Make clipboard operations universal, e.g. work with yanking.
vim.opt.clipboard = 'unnamedplus'

-- Disable keystroke flashing in the bottom right.
vim.opt.showcmd = false

-- Ignore casing while searching, UNLESS
-- \C or one or more capital letters in the search term.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default,
-- which prevents 'width flashing'.
vim.opt.signcolumn = 'yes'

-- Decrease update time and mapped sequence wait time.
vim.opt.updatetime = 250
vim.opt.timeoutlen = 250

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- :))))))
vim.opt.swapfile = false

-- Completion stuff.
vim.opt.completeopt = 'fuzzy,menu,menuone,noselect,popup'

-- Force a global statusbar.
vim.opt.laststatus = 3

-- Statusline. Does async stuff to try and keep it fast.
-- TODO: fix highlighting, the hl groups here are fked.
-- TODO: fix submodule support, add submodule marker
-- TODO: make the git branch + repo name based on cwd, not buffer.
vim.opt.statusline =
  '%#StatusLineNoBold#[%{v:lua.cwd_short()}] %#StatusLine#%{v:lua.git_repo()}%#StatusLineNoBold# %= %l/%L (%p%%)'

-- Put the absolute path of the current file in the winbar.
vim.opt.winbar = '%{v:lua.git_root_relative_filename()} %{%v:lua.buffer_git_status()%} %{%v:lua.diagnostics_summary()%}'

-- Use retrobox colorscheme.
vim.cmd('colorscheme retrobox')

-- Virtual text diagnostics to the right of problematic lines.
vim.diagnostic.config({
  virtual_text = true,
})

-- Vert split help.
vim.api.nvim_create_user_command('H', 'vert help <args>', {
  nargs = '?',
})

-- Vert split terminal.
vim.api.nvim_create_user_command('T', 'vert term <args>', {
  nargs = '?',
})

-- Easier exiting insert mode.
vim.keymap.set('i', 'jj', '<Esc>')

-- Navigate the default popup boxes easier.
vim.keymap.set({ 'i', 'c' }, '<C-j>', '<C-n>')
vim.keymap.set({ 'i', 'c' }, '<C-k>', '<C-p>')

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
  Snacks.picker.buffers()
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

-- Open oil in git repo root.
vim.keymap.set('n', '<C-->', function()
  local root = vim.fs.find('.git', { upward = true })[1]
  if not root then
    vim.notify('Not inside a git repo', vim.log.levels.WARN)
    return
  end

  root = vim.fs.dirname(root)
  require('plug.oil').open_float(root)
end)

-- Lua language server config.
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
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

vim.lsp.config['stylua'] = {
  cmd = { 'stylua', '--lsp' },
  filetypes = { 'lua' },
  root_markers = { '.stylua.toml' },
}

vim.lsp.config['deno'] = {
  cmd = { 'deno', 'lsp' },
  filetypes = { 'typescript' },
  root_markers = { 'deno.json' },
}

-- Enable language servers.
-- For lua, we use lua-language-server for everything except formatting.
-- We use stylua running in LSP mode (stylua --lsp) for formatting,
-- since it is noticeably much snappier.
vim.lsp.enable('lua')
vim.lsp.enable('stylua')

-- Deno LSP is goated, it does everything wicked fast.
vim.lsp.enable('deno')

-- Setup native autocomplete using the attached LSPs trigger character.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

function _G.diagnostics_summary()
  local sev = vim.diagnostic.severity
  local e = #vim.diagnostic.get(0, { severity = sev.ERROR })
  local w = #vim.diagnostic.get(0, { severity = sev.WARN })
  local h = #vim.diagnostic.get(0, { severity = sev.HINT })
  local i = #vim.diagnostic.get(0, { severity = sev.INFO })

  local parts = {}

  if e > 0 then
    table.insert(parts, '%#DiagnosticError#' .. e .. 'E' .. '%#WinBar#')
  end
  if w > 0 then
    table.insert(parts, '%#DiagnosticWarn#' .. w .. 'W' .. '%#WinBar#')
  end
  if h > 0 then
    table.insert(parts, '%#DiagnosticHint#' .. h .. 'H' .. '%#WinBar#')
  end
  if i > 0 then
    table.insert(parts, '%#DiagnosticInfo#' .. i .. 'I' .. '%#WinBar#')
  end

  return table.concat(parts, ' ')
end

-- Returns a formatted short string describing git repo root
-- and current HEAD. Uses buffer variables populated from gitsigns.
-- Do a nil check first, because if no buffers are open the dictionary
-- will not have been populated.
function _G.git_repo()
  if not vim.b.gitsigns_status_dict then
    return ''
  end

  local head = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.head
  local root = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.root

  local cwd_rel_to_git_root = vim.fs.relpath(vim.b.gitsigns_status_dict.root, vim.loop.cwd())
  local cwd_child_of_git_root = cwd_rel_to_git_root ~= nil

  if cwd_child_of_git_root then
    return vim.fs.basename(root) .. ' (' .. head .. ')'
  end

  return 'no git'
end

-- Get a version of cwd that uses ~ instead of the expanded name.
-- TODO: vim.loop is deprecated.
function _G.cwd_short()
  local cwd = vim.loop.cwd()
  local home = vim.loop.os_homedir()

  -- replace home path with ~
  cwd = cwd:gsub('^' .. home, '~')
  return cwd
end

-- Returns a string suitable for a statusline containing
-- a git change summation.
-- ex: [+30 ~27 -17].
function _G.buffer_git_status()
  if vim.b.gitsigns_status_dict == nil then
    return ''
  end

  local added = vim.b.gitsigns_status_dict.added
  local changed = vim.b.gitsigns_status_dict.changed
  local removed = vim.b.gitsigns_status_dict.removed

  local parts = {}

  if added > 0 then
    table.insert(parts, '%#GitSignsAdd#' .. '+' .. added .. '%#WinBar#')
  end
  if changed > 0 then
    table.insert(parts, '%#GitSignsChange#' .. '~' .. changed .. '%#WinBar#')
  end
  if removed > 0 then
    table.insert(parts, '%#GitSignsDelete#' .. '-' .. removed .. '%#WinBar#')
  end

  if added > 0 or changed > 0 or removed > 0 then
    return '[' .. table.concat(parts, ' ') .. ']'
  end

  return ''
end

-- Get the path, relative to the git root, of the file
-- open in the current buffer. If a parent git repo cannot
-- be found, return the absolute path of the file.
function _G.git_root_relative_filename()
  if vim.bo.buftype == 'terminal' then
    return 'terminal'
  end

  local file_abs = vim.api.nvim_buf_get_name(0)
  if vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.root then
    return file_abs:sub(#vim.b.gitsigns_status_dict.root + 2)
  end

  return file_abs
end

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

    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('justin-lsp-attach', { clear = false }),
      buffer = event.buf,
      callback = function()
        vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
      end,
    })
  end,
})
