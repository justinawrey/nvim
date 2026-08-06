-- Neovim has no built-in notion of a tab "name": a tabpage is just a container
-- of windows, and the label you see is whatever 'tabline' renders. So naming a
-- tab means stashing a name in a tabpage-local variable (t:tabname) and drawing
-- it ourselves.

-- Label for tab number `tabnr`: the explicit name if one was set, otherwise a
-- fixed placeholder.
local function label(tabnr)
  local name = vim.fn.gettabvar(tabnr, 'tabname', '')
  return name ~= '' and name or '[No Name]'
end

function _G.tabline()
  local parts = {}
  local current = vim.fn.tabpagenr()

  for tabnr = 1, vim.fn.tabpagenr('$') do
    -- '%<n>T' makes the label clickable and closes the region for tab <n>.
    table.insert(
      parts,
      (tabnr == current and '%#TabLineSel#' or '%#TabLine#')
        .. '%'
        .. tabnr
        .. 'T'
        .. ' '
        .. tabnr
        .. ': '
        .. label(tabnr)
        .. ' '
    )
  end

  -- '%T' ends the last clickable region, TabLineFill paints the leftover space.
  return table.concat(parts) .. '%#TabLineFill#%T'
end

-- Always show the tabline, even with a single tab, so renaming is visible.
vim.opt.showtabline = 2
vim.opt.tabline = '%!v:lua.tabline()'

-- :TabName foo  -> name the current tab
-- :TabName      -> clear the name (falls back to [No Name])
vim.api.nvim_create_user_command('TabName', function(opts)
  vim.t.tabname = opts.args
  vim.cmd.redrawtabline()
end, { nargs = '?', desc = 'Set the name of the current tabpage' })

