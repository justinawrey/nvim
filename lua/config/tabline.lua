local tab_branches = {}

local function get_branch_name(tabnr)
  local cwd = vim.fn.getcwd(-1, tabnr)
  vim.system({ 'git', '-C', cwd, 'branch', '--show-current' }, { text = true }, function(result)
    local branch = vim.trim(result.stdout or '')
    if branch == '' then
      tab_branches[tabnr] = tostring(tabnr)
    else
      tab_branches[tabnr] = branch
    end
    vim.schedule(function()
      vim.cmd('redrawtabline')
    end)
  end)
end

local function update_tab_branches()
  for i = 1, vim.fn.tabpagenr('$') do
    get_branch_name(i)
  end
end

vim.api.nvim_create_autocmd({ 'TabEnter', 'TabNew', 'TabClosed', 'DirChanged', 'FocusGained' }, {
  callback = update_tab_branches,
})

-- Initial population
update_tab_branches()

function _G.custom_tabline()
  local s = ''

  for i = 1, vim.fn.tabpagenr('$') do
    -- select the highlighting
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end

    s = s .. ' ' .. (tab_branches[i] or tostring(i)) .. ' '
  end

  return s
end

-- Tabline
vim.opt.tabline = '%= %{%v:lua.custom_tabline()%}'
