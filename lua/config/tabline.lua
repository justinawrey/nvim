local M = {}

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
