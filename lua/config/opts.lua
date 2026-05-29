-- Get line numbers.
vim.opt.number = true

-- vim.opt.messagesopt = 'wait:0,history:500'

-- Folds should start open.
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

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

-- Force a global statusbar.
vim.opt.laststatus = 3

vim.cmd('colorscheme gruvbox')

vim.api.nvim_set_hl(0, 'WinBar', { fg = '#a89984', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'WinBarNC', { fg = '#a89984', bg = 'NONE' })
-- Match signcolumn background to the editor background.
vim.api.nvim_set_hl(0, 'SignColumn', { bg = '#282828' })

-- Virtual text diagnostics to the right of problematic lines.
vim.diagnostic.config({ virtual_text = true })

vim.api.nvim_create_user_command('Wc', function(opts)
  local tabline = require('config.tabline')
  if opts.args ~= '' then
    local path = vim.fn.expand(opts.args)
    for i, wt in ipairs(tabline.worktrees) do
      if wt.path == path then
        tabline.remove(i)
        return
      end
    end
  else
    local current_tab = vim.api.nvim_get_current_tabpage()
    for i, tp in ipairs(vim.api.nvim_list_tabpages()) do
      if tp == current_tab then
        tabline.remove(i)
        return
      end
    end
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('Wa', function(opts)
  require('config.tabline').add(opts.args)
end, { nargs = 1, complete = 'dir' })

vim.api.nvim_create_user_command('Wcd', function(opts)
  require('config.tabline').cd(opts.args)
end, { nargs = 1, complete = 'dir' })

-- Control line numbers and signcolumn based on buffer type.
local no_number = { terminal = true, nofile = true, prompt = true }
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TermOpen' }, {
  callback = function()
    vim.schedule(function()
      if no_number[vim.bo.buftype] then
        vim.opt_local.number = false
        vim.opt_local.signcolumn = 'no'
      else
        vim.opt_local.number = true
        vim.opt_local.signcolumn = 'yes'
      end
    end)
  end,
})
