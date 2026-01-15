_G.justin_tabline = {
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
}

vim.api.nvim_create_user_command('Tname', function(args)
  if #args.fargs ~= 2 then
    vim.notify('usage: Tname <number> <name>')
    return
  end

  local number = args.fargs[1]
  local name = args.fargs[2]

  _G.justin_tabline[tonumber(number)] = name
  vim.api.nvim_command('redrawtabline')
end, { nargs = '*' })

function _G.custom_tabline()
  local s = ''

  for i = 1, vim.fn.tabpagenr('$') do
    -- select the highlighting
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end

    s = s .. ' ' .. _G.justin_tabline[i] .. ' '
  end

  -- after the last tab page fill with TabLineFill and reset tab page nr
  -- s = s .. '%#TabLineFill#%T'
  --
  -- -- right-align the label to close the current tab page
  -- if vim.fn.tabpagenr('$') > 1 then
  --   s = s .. '%=%#TabLine#%999Xclose'
  -- end

  return s
end

-- Tabline
vim.opt.tabline = '%= %{%v:lua.custom_tabline()%}'
