-- Get the path, relative to the git root, of the file
-- open in the current buffer. If a parent git repo cannot
-- be found, return the absolute path of the file.
function _G.git_root_relative_filename()
  if vim.bo.buftype == 'terminal' then
    return 'terminal'
  end

  local file_abs = vim.api.nvim_buf_get_name(0)
  if vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.root then
    return file_abs:sub(#vim.b.gitsigns_status_dict.root + 2)
  end

  return file_abs
end

-- Returns a string suitable for a statusline containing
-- a git change summation.
-- ex: [+30 ~27 -17].
function _G.buffer_git_status()
  if vim.b.gitsigns_status_dict == nil then
    return ''
  end

  local added = vim.b.gitsigns_status_dict.added
  local changed = vim.b.gitsigns_status_dict.changed
  local removed = vim.b.gitsigns_status_dict.removed

  local parts = {}

  if added > 0 then
    table.insert(parts, '%#GitSignsAdd#' .. '+' .. added .. '%#WinBar#')
  end
  if changed > 0 then
    table.insert(parts, '%#GitSignsChange#' .. '~' .. changed .. '%#WinBar#')
  end
  if removed > 0 then
    table.insert(parts, '%#GitSignsDelete#' .. '-' .. removed .. '%#WinBar#')
  end

  if added > 0 or changed > 0 or removed > 0 then
    return '[' .. table.concat(parts, ' ') .. ']'
  end

  return ''
end

function _G.diagnostics_summary()
  local sev = vim.diagnostic.severity
  local e = #vim.diagnostic.get(0, { severity = sev.ERROR })
  local w = #vim.diagnostic.get(0, { severity = sev.WARN })
  local h = #vim.diagnostic.get(0, { severity = sev.HINT })
  local i = #vim.diagnostic.get(0, { severity = sev.INFO })

  local parts = {}

  if e > 0 then
    table.insert(parts, '%#DiagnosticError#' .. e .. 'E' .. '%#WinBar#')
  end
  if w > 0 then
    table.insert(parts, '%#DiagnosticWarn#' .. w .. 'W' .. '%#WinBar#')
  end
  if h > 0 then
    table.insert(parts, '%#DiagnosticHint#' .. h .. 'H' .. '%#WinBar#')
  end
  if i > 0 then
    table.insert(parts, '%#DiagnosticInfo#' .. i .. 'I' .. '%#WinBar#')
  end

  return table.concat(parts, ' ')
end

-- Put the absolute path of the current file in the winbar.
vim.opt.winbar = '%{v:lua.git_root_relative_filename()} %{%v:lua.buffer_git_status()%} %{%v:lua.diagnostics_summary()%}'
