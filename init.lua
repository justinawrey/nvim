-- The Roslyn language server and all of its .dlls are manually downloaded to
-- ~/.local/bin/roslyn, so add it to the path before trying to load the plugin.
vim.env.PATH = vim.env.PATH .. ':' .. vim.fs.normalize('~/.local/bin/roslyn')

-- Space leader.
-- Do this before requiring plugins because...
-- well... I dont even know at this point :shrug:
vim.keymap.set('n', '<space>', '<nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Plugins, which are cloned as submodules in pack/*/start/*.
-- TODO: still need to set up hunk stage/unstage/preview/reset keybindings.
require('config.plug.snacks')
require('config.plug.gitsigns')
require('config.plug.oil')
require('config.plug.autopairs')
require('config.plug.blink')

-- Options and keymaps, a.k.a a bunch of
-- one-off key-val settings, not really any logic.
require('config.opts')
require('config.keymaps')

-- Custom statusline and winbar.
require('config.statusline')
require('config.winbar')

-- Do LSP setup in this order:
-- 1. Define common configuration
-- 1. Define language specific configuration
-- 1. Define 'LspAttach' autocmd
require('config.lsp.common')
require('config.lsp.lua')
require('config.lsp.deno')
require('config.lsp.roslyn')
require('config.lsp.attach')
