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

-- Force a global statusbar.
vim.opt.laststatus = 3

vim.cmd('colorscheme retrobox')

-- Virtual text diagnostics to the right of problematic lines.
vim.diagnostic.config({ virtual_text = true })
