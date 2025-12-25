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
  cwd = cwd:gsub('^' .. home, '~')
  return cwd
end

-- Statusline. Does async stuff to try and keep it fast.
-- TODO: fix highlighting, the hl groups here are fked.
-- TODO: fix submodule support, add submodule marker
-- TODO: make the git branch + repo name based on cwd, not buffer.
vim.opt.statusline =
  '%#StatusLineNoBold#[%{v:lua.cwd_short()}] %#StatusLine#%{v:lua.git_repo()}%#StatusLineNoBold# %= %l/%L (%p%%)'
