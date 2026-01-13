-- note this only works if cwd is the root wherever
-- this repo is cloned... kinda wack but its mine so w/e.
-- just use nvime alias
require('init')

-- Open default tabs the way I like it
vim.cmd('tabe')
vim.cmd('tcd ~')
vim.cmd('e ~/.config/daily/daily.md')
vim.cmd('tabn 1')
vim.cmd('Tname 1 zsh')
vim.cmd('Tname 2 notes')
