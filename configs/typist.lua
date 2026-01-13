-- note this only works if cwd is the root wherever
-- this repo is cloned... kinda wack but its mine so w/e.
-- just use nvime alias
require('init')

-- Open default tabs the way I like it
vim.cmd('cd ~/typist/Assets/Scripts')
vim.cmd('tabe')
vim.cmd('tcd ~/typist/Packages/oyster-kit')
vim.cmd('tabe')
vim.cmd('tcd ~')
vim.cmd('e daily.md')
vim.cmd('tabn 1')
vim.cmd('Tname 1 typist')
vim.cmd('Tname 2 oyster-kit')
vim.cmd('Tname 3 notes')
