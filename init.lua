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
vim.opt.showcmd = false

-- Make the autocomplete usable, otherwise the first menu item
-- is auto-selected which fucking sucks.
vim.cmd 'set completeopt+=noselect'

-- Force a global statusbar.
vim.cmd 'set laststatus=3'

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
vim.keymap.set('n', '<S-j>', '8j')
vim.keymap.set('n', '<S-k>', '8k')

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

-- Open oil in parent dir.
vim.keymap.set('n', '-', '<CMD>Oil --float<CR>')

-- Open oil in git repo root.
vim.keymap.set("n", "<C-->", function()
  local root = vim.fs.find(".git", { upward = true })[1]
  if not root then
    vim.notify("Not inside a git repo", vim.log.levels.WARN)
    return
  end

  root = vim.fs.dirname(root)
  require("oil").open_float(root)
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

-- Attempts to find git repo. Returns nil if not parent dir
-- could be find with a .git folder.
function _G.git_repo()
  local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")

  if git_dir == "" then
    return 'no git'
  end

  -- When cwd is the root of the git repo, handle it as a special
  -- case. There is probably a more elegant way to do this.
  local repo
  if git_dir == ".git" then
    repo = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  else
    repo = vim.fn.fnamemodify(git_dir, ":h:t")
  end

  local branch = vim.fn.systemlist('git branch --show-current')[1]
  return string.format('%s (%s)', repo, branch)
end

-- Get a version of cwd that uses ~ instead of the expanded name.
function _G.cwd_short()
  local cwd = vim.fn.getcwd()
  local home = vim.loop.os_homedir()

  -- replace home path with ~
  cwd = cwd:gsub("^" .. home, "~")
  return cwd
end

-- Get the path, relative to the git root, of the file
-- open in the current buffer. If a parent git repo cannot
-- be found, return the absolute path of the file.
function _G.git_root_relative_filename()
  if vim.bo.buftype == 'terminal' then
    return 'terminal'
  end

  local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
  local file_abs = vim.fn.expand("%:p")

  if git_dir == nil or git_dir == "" then
    local home = vim.loop.os_homedir()
    return file_abs:gsub("^" .. home, "~")
  end

  if git_dir == ".git" then
    git_dir = vim.fn.getcwd()
  else
    git_dir = vim.fn.fnamemodify(git_dir, ":h")
  end

  return file_abs:sub(#git_dir + 2)
end

function _G.buffer_git_status()
  local status = vim.b.gitsigns_status
  if status == nil then
    return ""
  end

  if status == "" then
    return ""
  end

  return '[' .. status .. ']'
end

-- A highlight group for bold status line characters.
vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

-- Set a statusline that looks like the following:
-- nvim (main) [~/.config/nvim/v2]     10/100 (10%)
vim.opt.statusline = "%#StatusLineBold#%{v:lua.git_repo()}%* [%{v:lua.cwd_short()}] %= %l/%L (%p%%)"

-- Put the absolute path of the current file in the winbar.
vim.opt.winbar = "%{v:lua.git_root_relative_filename()} %{v:lua.buffer_git_status()}"

-- Use retrobox colorscheme.
vim.cmd 'colorscheme retrobox'

-- Gitsigns, for nice info in the left sidebar and change counts.
require('plugins.gitsigns')

-- Oil, for file editing like a buffer.
---@diagnostic disable-next-line: different-requires
require('plugins.oil')
