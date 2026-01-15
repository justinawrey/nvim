-- note this only works if cwd is the root wherever
-- this repo is cloned... kinda wack but its mine so w/e.
-- just use nvime alias
require('init')

-- Open default tabs the way I like it
vim.cmd('cd ~/goblin-client-tools')
vim.cmd('tabe')
vim.cmd('tcd ~/src/firespotter/')
vim.cmd('tabe')
vim.cmd('tcd ~/.config/daily')
vim.cmd('e ~/.config/daily/daily.md')
vim.cmd('tabn 1')
vim.cmd('Tname 1 goblin-client-tools')
vim.cmd('Tname 2 firespotter')
vim.cmd('Tname 3 notes')
