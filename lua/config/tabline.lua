local M = {}

local repo_shorthands = {
  ['goblin-client-tools'] = 'gct',
  ['dialtone'] = 'dt',
  ['web-clients'] = 'wc',
  ['firespotter'] = 'fs',
}

--- Source of truth: ordered list of open worktrees.
--- Index position corresponds to tabpage position.
--- Entry 1 is always the scratch tab: { scratch = true }
--- Remaining entries: { path = string, branch = string, repo = string, state = string }
M.worktrees = { { scratch = true } }

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

function M.add(path)
  path = vim.fn.expand(path)
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

  local insert_index = vim.fn.tabpagenr()
  resolve_git_info(path, function(branch, repo)
    table.insert(M.worktrees, insert_index, { path = path, branch = branch, repo = repo, state = 'idle' })
    vim.cmd('redrawtabline')
  end)
end

function M.ch_state(index, state)
  if not M.worktrees[index] then
    return
  end
  M.worktrees[index].state = state
  vim.cmd('redrawtabline')
end

function M.remove(index)
  if index == 1 then
    return
  end

  local tabpages = vim.api.nvim_list_tabpages()
  local target = tabpages[index]
  if not target then
    return
  end

  vim.api.nvim_set_current_tabpage(target)
  vim.cmd('tabclose')

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

  if not index or not M.worktrees[index] or M.worktrees[index].scratch then
    return
  end

  M.worktrees[index].path = path
  vim.cmd('tcd ' .. vim.fn.fnameescape(path))

  resolve_git_info(path, function(branch, repo)
    M.worktrees[index].branch = branch
    M.worktrees[index].repo = repo
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
    if wt.scratch then
      table.insert(parts, hl .. ' scratch ')
    else
      local prefix = state_chars[wt.state] or ''
      if prefix ~= '' then
        prefix = prefix .. ' '
      end
      table.insert(parts, hl .. ' ' .. prefix .. wt.branch .. ' [' .. wt.repo .. '] ')
    end
  end

  return '%#TabLineFill#%=' .. table.concat(parts)
end

_G.tabline_render = M.render
vim.opt.tabline = '%!v:lua.tabline_render()'
update_showtabline()

vim.api.nvim_set_current_tabpage(vim.api.nvim_list_tabpages()[1])
setup_tab(vim.fn.expand('~/wts'))

return M
