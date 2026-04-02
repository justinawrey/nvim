local M = {}

local repo_shorthands = {
  ['goblin-client-tools'] = 'gct',
  ['dialtone'] = 'dt',
  ['web-clients'] = 'wc',
  ['firespotter'] = 'fs',
}

--- Source of truth: ordered list of open worktrees.
--- Index position corresponds to tabpage position.
--- Each entry: { path = string, branch = string, repo = string }
M.worktrees = {}

-- Alternating highlight groups for legibility.
-- Odd entries use bg1 (#3c3836), even entries use bg0 (#282828).
vim.api.nvim_set_hl(0, 'TabLineAlt', { fg = '#7c6f64', bg = '#282828' })
vim.api.nvim_set_hl(0, 'TabLineSelAlt', { fg = '#b8bb26', bg = '#282828' })

local function update_showtabline()
  vim.opt.showtabline = #M.worktrees > 0 and 2 or 0
end

local function setup_tab(path)
  vim.cmd('tcd ' .. vim.fn.fnameescape(path))
  vim.cmd('ter claude')
  local term_win = vim.api.nvim_get_current_win()
  Snacks.picker.explorer({
    exclude = { '*.meta' },
    hidden = true,
    ignored = true,
    layout = { layout = { width = 20, min_width = 20 } },
    on_show = function()
      vim.api.nvim_set_current_win(term_win)
      vim.cmd('startinsert')
    end,
  })
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

  if #M.worktrees == 0 then
    setup_tab(path)
  else
    vim.cmd('tabnew')
    setup_tab(path)
  end

  local insert_index = #M.worktrees == 0 and 1 or vim.fn.tabpagenr()
  resolve_git_info(path, function(branch, repo)
    table.insert(M.worktrees, insert_index, { path = path, branch = branch, repo = repo })
    update_showtabline()
    vim.cmd('redrawtabline')
  end)
end

function M.remove(index)
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

  update_showtabline()
  vim.cmd('redrawtabline')
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
    table.insert(parts, hl .. ' ' .. wt.branch .. ' [' .. wt.repo .. '] ')
  end

  return '%#TabLineFill#%=' .. table.concat(parts)
end

_G.tabline_render = M.render
vim.opt.tabline = '%!v:lua.tabline_render()'
update_showtabline()

return M
