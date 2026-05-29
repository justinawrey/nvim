local M = {}

local repo_shorthands = {
  ['goblin-client-tools'] = 'gct',
  ['dialtone'] = 'dt',
  ['web-clients'] = 'wc',
  ['firespotter'] = 'fs',
}

--- Source of truth: ordered list of open worktrees.
--- Index position corresponds to tabpage position.
--- Each entry: { path = string, branch = string, repo = string, state = string }
--- branch/repo are empty for non-git directories, which are labeled by folder name.
M.worktrees = {}

-- Alternating highlight groups for legibility.
-- Odd entries use bg1 (#3c3836), even entries use bg0 (#282828).
vim.api.nvim_set_hl(0, 'TabLineAlt', { fg = '#7c6f64', bg = '#282828' })
vim.api.nvim_set_hl(0, 'TabLineSelAlt', { fg = '#b8bb26', bg = '#282828' })

local state_chars = {
  idle = '',
  thinking = 't',
  needs_attn = '●',
}

local function update_showtabline()
  vim.opt.showtabline = 2
end

local function setup_tab(path)
  vim.cmd('tcd ' .. vim.fn.fnameescape(path))
end

-- Tab label: `branch [repo]` for git repos, else the folder name.
local function label_for(wt)
  if wt.branch and wt.branch ~= '' and wt.repo and wt.repo ~= '' then
    return wt.branch .. ' [' .. wt.repo .. ']'
  end
  local path = (wt.path or ''):gsub('/+$', '')
  return vim.fn.fnamemodify(path, ':t')
end

local function resolve_git_info(path, callback)
  local branch, repo

  local function try_finish()
    if branch and repo then
      vim.schedule(function()
        callback(branch, repo)
      end)
    end
  end

  vim.system({ 'git', '-C', path, 'branch', '--show-current' }, {}, function(result)
    local out = vim.trim(result.stdout or '')
    if out ~= '' then
      branch = out
      try_finish()
    else
      vim.system({ 'git', '-C', path, 'rev-parse', '--short', 'HEAD' }, {}, function(r2)
        branch = vim.trim(r2.stdout or '')
        try_finish()
      end)
    end
  end)

  vim.system({ 'git', '-C', path, 'remote', 'get-url', 'origin' }, {}, function(result)
    local url = vim.trim(result.stdout or '')
    local full = url:match('([^/]+)%.git$') or url:match('([^/]+)$') or url
    repo = repo_shorthands[full] or full
    try_finish()
  end)
end

-- Insert an entry for `path` at `index`, then fill in git info asynchronously.
-- The callback updates the entry object directly, so it stays correct even if
-- tab indices shift before git resolves.
local function register(path, index)
  local entry = { path = path, branch = nil, repo = nil, state = 'idle' }
  table.insert(M.worktrees, index, entry)
  vim.cmd('redrawtabline')
  resolve_git_info(path, function(branch, repo)
    entry.branch = branch
    entry.repo = repo
    vim.cmd('redrawtabline')
  end)
end

function M.add(path)
  path = vim.fn.expand(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.notify('Wa: not a directory: ' .. path, vim.log.levels.ERROR)
    return
  end
  for i, wt in ipairs(M.worktrees) do
    if wt.path == path then
      local tabpages = vim.api.nvim_list_tabpages()
      if tabpages[i] then
        vim.api.nvim_set_current_tabpage(tabpages[i])
      end
      return
    end
  end

  vim.cmd('tabnew')
  setup_tab(path)
  register(path, vim.fn.tabpagenr())
end

function M.ch_state(index, state)
  if not M.worktrees[index] then
    return
  end
  M.worktrees[index].state = state
  vim.cmd('redrawtabline')
end

function M.remove(index)
  local tabpages = vim.api.nvim_list_tabpages()
  if #tabpages <= 1 then
    -- Neovim always keeps at least one tab page open.
    return
  end

  local target = tabpages[index]
  if not target then
    return
  end

  vim.api.nvim_set_current_tabpage(target)
  vim.cmd('tabclose')

  local wt = M.worktrees[index]
  if wt then
    require('config.lazygit').close_for(wt.path)
  end

  table.remove(M.worktrees, index)

  local focus_index = index > 1 and index - 1 or 1
  local remaining = vim.api.nvim_list_tabpages()
  if remaining[focus_index] then
    vim.api.nvim_set_current_tabpage(remaining[focus_index])
  end

  vim.cmd('redrawtabline')
end

function M.cd(path)
  path = vim.fn.expand(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.notify('Wcd: not a directory: ' .. path, vim.log.levels.ERROR)
    return
  end

  local tabpages = vim.api.nvim_list_tabpages()
  for i, wt in ipairs(M.worktrees) do
    if wt.path == path and tabpages[i] then
      vim.api.nvim_set_current_tabpage(tabpages[i])
      return
    end
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  local index
  for i, tp in ipairs(tabpages) do
    if tp == current_tab then
      index = i
      break
    end
  end

  if not index or not M.worktrees[index] then
    return
  end

  local entry = M.worktrees[index]
  entry.path = path
  vim.cmd('tcd ' .. vim.fn.fnameescape(path))

  resolve_git_info(path, function(branch, repo)
    entry.branch = branch
    entry.repo = repo
    vim.cmd('redrawtabline')
  end)
end

function M.render()
  if #M.worktrees == 0 then
    return ''
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()
  local current_index = 1
  for i, tp in ipairs(tabpages) do
    if tp == current_tab then
      current_index = i
      break
    end
  end

  local parts = {}
  for i, wt in ipairs(M.worktrees) do
    local even = i % 2 == 0
    local hl
    if i == current_index then
      hl = even and '%#TabLineSelAlt#' or '%#TabLineSel#'
    else
      hl = even and '%#TabLineAlt#' or '%#TabLine#'
    end
    local prefix = state_chars[wt.state] or ''
    if prefix ~= '' then
      prefix = prefix .. ' '
    end
    table.insert(parts, hl .. ' ' .. prefix .. label_for(wt) .. ' ')
  end

  return '%#TabLineFill#%=' .. table.concat(parts)
end

_G.tabline_render = M.render
vim.opt.tabline = '%!v:lua.tabline_render()'
update_showtabline()

-- Register the initial tab as a normal entry for nvim's launch directory.
vim.api.nvim_set_current_tabpage(vim.api.nvim_list_tabpages()[1])
register(vim.fn.getcwd(), 1)

return M
