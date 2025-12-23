-- Add the config path to package.path so I can relatively
-- require like: require('plug.some-plug').
-- Feels weird, idk if this is the right, but whatever, it works.
-- Might act weirdly if init files are somewhere other than
-- the standard config paths but... w/e
package.path = vim.fn.stdpath('config') .. '/?.lua;' .. package.path

-- Space leader.
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

-- Rounded diagnostic window borders that are easier to see.
vim.opt.winborder = 'rounded'

-- Make clipboard operations universal, e.g. work with yanking.
vim.opt.clipboard = 'unnamedplus'

-- Disable keystroke flashing in the bottom right.
vim.opt.showcmd = true

-- Make the autocomplete usable, otherwise the first menu item
-- is auto-selected which fucking sucks.
vim.cmd 'set completeopt+=noselect'

-- Force a global statusbar.
vim.cmd 'set laststatus=3'

-- A highlight group for bold status line characters.
vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })


-- Statusline. Does async stuff to try and keep it fast.
-- TODO: Why bolding no work?
-- TODO: both the winbar and statusbars dont work well with submodules.
vim.opt.statusline =
"[%{v:lua.cwd_short()}] %#StatusLineBold#%{v:lua.git_repo()}%#StatusLine# %= %l/%L (%p%%)"

-- Put the absolute path of the current file in the winbar.
vim.opt.winbar = "%{v:lua.git_root_relative_filename()} %{v:lua.buffer_git_status()}"

-- Use retrobox colorscheme.
vim.cmd 'colorscheme retrobox'

-- Virtual text diagnostics to the right of problematic lines.
vim.diagnostic.config {
  virtual_text = true,
}

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

-- Open oil in cwd.
vim.keymap.set('n', '-', '<CMD>Oil --float .<CR>')

-- Open oil in git repo root.
vim.keymap.set("n", "<C-->", function()
  local root = vim.fs.find(".git", { upward = true })[1]
  if not root then
    vim.notify("Not inside a git repo", vim.log.levels.WARN)
    return
  end

  root = vim.fs.dirname(root)
  require("plug.oil").open_float(root)
end)

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
    },
  },
}

-- Enable lua language server.
vim.lsp.enable 'luals'

-- Setup native autocomplete using the attached LSPs trigger character.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

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
  cwd = cwd:gsub("^" .. home, "~")
  return cwd
end

-- Returns a string suitable for a statusline containing
-- a git change summation.
-- ex: [+30 ~27 -17].
function _G.buffer_git_status()
  if vim.b.gitsigns_status == '' or vim.b.gitsigns_status == nil then
    return ''
  end

  return '[' .. vim.b.gitsigns_status .. ']'
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
