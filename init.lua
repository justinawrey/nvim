-- I stuff roslyn here...
vim.env.PATH = vim.env.PATH .. ':' .. vim.fs.normalize('~/.local/bin/roslyn')

-- Claude Code turns on synchronized output (DEC mode 2026) when TERM_PROGRAM is a
-- known terminal (ghostty, iTerm, WezTerm, ...). Inside nvim's :terminal that value
-- is inherited from the outer terminal, so Claude batches frames -- but the actual
-- emulator is nvim's libvterm, which renders them garbled. Unsetting it makes Claude
-- fall back to plain rendering. Only Claude reads this var, so nothing else breaks.
vim.env.TERM_PROGRAM = nil

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
require('config.plug.nonels')
require('config.plug.treesitter')
require('config.plug.gruvbox')
require('config.plug.md')

-- Options and keymaps, a.k.a a bunch of
-- one-off key-val settings, not really any logic.
require('config.opts')
require('config.keymaps')
require('config.urls')

-- Custom statusline and winbar.
require('config.statusline')
require('config.winbar')
require('config.recompile')
require('config.notify')

-- Do LSP setup in this order:
--
-- 1. Define common configuration
-- 1. Define language specific configuration
-- 1. Define 'LspAttach' autocmd
--
-- NOTE: if you're going to use two LSPs for the same
-- filetypes like im doing here with lua_language_server + stylua
-- and roslyn + csharpier via nonels, make sure to not
-- double attach in config.lsp.attach.
require('config.lsp.common')
require('config.lsp.eslint')
require('config.lsp.lua')
require('config.lsp.md')
require('config.lsp.deno')
require('config.lsp.ts')
require('config.lsp.vue')
require('config.lsp.roslyn')
require('config.lsp.attach')
