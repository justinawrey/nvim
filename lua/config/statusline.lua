vim.g.justin_git_repo = ''
vim.g.justin_git_branch = 'unimpl'

vim.api.nvim_create_autocmd({ 'DirChanged', 'VimEnter', 'BufEnter', 'FocusGained' }, {
  callback = function()
    vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }, function(result)
      local repo = 'no git'
      if result.code == 0 then
        local path = vim.trim(result.stdout)
        if path ~= '' then
          repo = vim.fn.fnamemodify(path, ':t')
        end
      end

      vim.g.justin_git_repo = repo

      vim.schedule(function()
        vim.api.nvim_command('redrawstatus')
      end)
    end)
  end,
})

-- Returns a formatted short string describing git repo root
-- and current HEAD. Uses buffer variables populated from gitsigns.
-- Do a nil check first, because if no buffers are open the dictionary
-- will not have been populated.
-- TODO: implement vim.g.justin_git_branch
function _G.git_repo()
  if vim.g.justin_git_repo == nil or vim.g.justin_git_repo == 'no git' then
    return 'no git'
  end

  return vim.g.justin_git_repo .. ' (' .. vim.g.justin_git_branch .. ')'
end

-- Get a version of cwd that uses ~ instead of the expanded name.
function _G.cwd_short()
  local cwd = vim.loop.cwd()
  local home = vim.loop.os_homedir()

  -- replace home path with ~
  cwd = cwd:gsub('^' .. home, '~')
  return cwd
end

-- TODO: really need some sort of feedback/loading indicator here...
-- This will require hooking into the recompilation state in the unity editor
-- HTTP server and sending an 'ok' response when its done.
-- TODO: maybe introduce a new icon for 'compilation error'
function _G.cs_dirty()
  if vim.g.any_cs_file_dirty then
    return 'cs dirty'
  end

  return ''
end

-- Statusline. Does async stuff to try and keep it fast.
-- TODO: fix highlighting, the hl groups here are fked.
-- TODO: add submodule marker?
-- TODO: show num files changed, added, removed. I thought maybe we could
-- hook into gitsigns for this but the root git obj provided by gitsigns
-- is based on the open buffer, which doesnt really fit my workflow super well.
-- ill probably have to track my own git object for statusline purposes,
-- hopefully I can just hook into "cwd" events, not sure if thats a thing in neovim
vim.opt.statusline =
  '%#StatusLineNoBold#[%{v:lua.cwd_short()}] %#StatusLine#%{v:lua.git_repo()}%#StatusLineNoBold# %= %{v:lua.cs_dirty()} %l/%L (%p%%)'
