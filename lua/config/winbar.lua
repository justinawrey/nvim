local function relative_path(from, to)
  from = vim.fs.normalize(from)
  to = vim.fs.normalize(to)

  -- split paths
  local function split(p)
    return vim.split(p, '/', { plain = true, trimempty = true })
  end

  local from_parts = split(from)
  local to_parts = split(to)

  -- remove common prefix
  local i = 1
  while from_parts[i] and to_parts[i] and from_parts[i] == to_parts[i] do
    i = i + 1
  end

  local rel = {}

  -- go up for remaining `from` parts
  for _ = i, #from_parts do
    table.insert(rel, '..')
  end

  -- go down into `to`
  for j = i, #to_parts do
    table.insert(rel, to_parts[j])
  end

  return #rel > 0 and table.concat(rel, '/') or '.'
end

--
-- Get the path, relative to the git root, of the file
-- open in the current buffer. If a parent git repo cannot
-- be found, return the absolute path of the file.
function _G.relative_filename()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].is_welcome then
    return ''
  end

  if vim.bo.buftype == 'terminal' then
    return 'terminal'
  end

  local file_abs = vim.api.nvim_buf_get_name(0)
  local cwd_abs = vim.loop.cwd()

  return relative_path(cwd_abs, file_abs)
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

  if added ~= nil and added > 0 then
    table.insert(parts, '%#GitSignsAdd#' .. '+' .. added .. '%#WinBar#')
  end
  if changed ~= nil and changed > 0 then
    table.insert(parts, '%#GitSignsChange#' .. '~' .. changed .. '%#WinBar#')
  end
  if removed ~= nil and removed > 0 then
    table.insert(parts, '%#GitSignsDelete#' .. '-' .. removed .. '%#WinBar#')
  end

  if #parts > 0 then
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

vim.opt.winbar = '%{v:lua.relative_filename()} %{%v:lua.buffer_git_status()%} %{%v:lua.diagnostics_summary()%}'
