local M = {}

--- Source of truth: ordered list of open worktrees.
--- Index position corresponds to tabpage position.
--- Each entry: { path = string, branch = string, repo = string }
M.worktrees = {}

local function update_showtabline()
  vim.opt.showtabline = #M.worktrees > 0 and 2 or 0
end

function M.add(path, branch, repo)
  table.insert(M.worktrees, { path = path, branch = branch, repo = repo })
  update_showtabline()
  vim.cmd('redrawtabline')
end

function M.remove(index)
  table.remove(M.worktrees, index)
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
    local hl = i == current_index and '%#TabLineSel#' or '%#TabLine#'
    table.insert(parts, hl .. ' ' .. wt.branch .. ' [' .. wt.repo .. '] ')
  end

  table.insert(parts, '%#TabLineFill#')
  return table.concat(parts)
end

_G.tabline_render = M.render
vim.opt.tabline = '%!v:lua.tabline_render()'
update_showtabline()

return M
