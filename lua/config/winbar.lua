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

-- The winbar of the active window gets a light orange background so it's
-- obvious which buffer has focus. Neovim already picks WinBar for the current
-- window and WinBarNC for the others, but the embedded highlight groups
-- (gitsigns, diagnostics) carry their own background, which would punch holes
-- in the orange run. So for every group used inside the winbar we derive a
-- <Group>WinBar variant that keeps the foreground and takes the orange
-- background, and pick between the two depending on which window is drawing.
local BG = '#7a4526'
local FG = '#ebdbb2'

local derived = {
  'GitSignsAdd',
  'GitSignsChange',
  'GitSignsDelete',
  'DiagnosticError',
  'DiagnosticWarn',
  'DiagnosticHint',
  'DiagnosticInfo',
}

local function set_hl()
  -- Active window: dark text on light orange. Inactive: unchanged.
  vim.api.nvim_set_hl(0, 'WinBar', { fg = FG, bg = BG })
  vim.api.nvim_set_hl(0, 'WinBarNC', { fg = '#a89984', bg = 'NONE' })

  for _, name in ipairs(derived) do
    local base = vim.api.nvim_get_hl(0, { name = name, link = false })
    vim.api.nvim_set_hl(0, name .. 'WinBar', { fg = base.fg, bold = base.bold, bg = BG })
  end
end

set_hl()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('config.winbar', { clear = true }),
  callback = set_hl,
})

-- Is the window currently being rendered the focused one?
local function active()
  return vim.g.statusline_winid == vim.api.nvim_get_current_win()
end

-- '%#Group#' for the window being rendered.
local function hl(name)
  if name == nil then
    return active() and '%#WinBar#' or '%#WinBarNC#'
  end

  return '%#' .. name .. (active() and 'WinBar' or '') .. '#'
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
    local name = vim.b[buf].term_name
    return name and ('term: ' .. name) or 'term'
  end

  local file_abs = vim.api.nvim_buf_get_name(0)
  -- Unnamed buffers (e.g. the scratch buffer left behind when a tabpage's last
  -- window is closed) have no path to show.
  if file_abs == '' then
    return ''
  end
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
    table.insert(parts, hl('GitSignsAdd') .. '+' .. added .. hl())
  end
  if changed ~= nil and changed > 0 then
    table.insert(parts, hl('GitSignsChange') .. '~' .. changed .. hl())
  end
  if removed ~= nil and removed > 0 then
    table.insert(parts, hl('GitSignsDelete') .. '-' .. removed .. hl())
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
    table.insert(parts, hl('DiagnosticError') .. e .. 'E' .. hl())
  end
  if w > 0 then
    table.insert(parts, hl('DiagnosticWarn') .. w .. 'W' .. hl())
  end
  if h > 0 then
    table.insert(parts, hl('DiagnosticHint') .. h .. 'H' .. hl())
  end
  if i > 0 then
    table.insert(parts, hl('DiagnosticInfo') .. i .. 'I' .. hl())
  end

  return table.concat(parts, ' ')
end

function _G.winbar()
  local ft = vim.bo.filetype
  if ft == 'snacks_layout_box' then
    return ''
  end

  return relative_filename() .. ' ' .. buffer_git_status() .. ' ' .. diagnostics_summary()
end

vim.opt.winbar = '%{%v:lua.winbar()%}'
