-- Dump the live layout of the running Neovim instance: tabpages (with their
-- custom t:tabname), the windows in each, and every terminal buffer with its
-- <leader>n name, job channel and term:// uri.
--
-- Invoke over RPC, letting Neovim locate this file on its runtimepath so that
-- nothing hardcodes an install path:
--   nvim --server "$NVIM" --remote-expr \
--     "luaeval(\"dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/state.lua', false)[1])\")"

local out = {}

local function add(fmt, ...)
  out[#out + 1] = string.format(fmt, ...)
end

local function buf_desc(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return 'buf=? <invalid>'
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    name = '[No Name]'
  end
  local desc = string.format('buf=%d %s %s', buf, vim.bo[buf].buftype ~= '' and vim.bo[buf].buftype or 'file', name)
  local term_name = vim.b[buf].term_name
  if term_name and term_name ~= '' then
    desc = desc .. string.format(' name=%q', term_name)
  end
  return desc
end

local current_tab = vim.api.nvim_get_current_tabpage()
local current_win = vim.api.nvim_get_current_win()

add('TABPAGES')
for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
  local nr = vim.api.nvim_tabpage_get_number(tab)
  local tabname = vim.t[tab].tabname
  add(
    '  %stab %d  name=%s',
    tab == current_tab and '* ' or '  ',
    nr,
    (tabname and tabname ~= '') and tabname or '[No Name]'
  )
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local cfg = vim.api.nvim_win_get_config(win)
    add(
      '      %swin %d %s %s',
      win == current_win and '* ' or '  ',
      win,
      cfg.relative ~= '' and '(float)' or '',
      buf_desc(vim.api.nvim_win_get_buf(win))
    )
  end
end

add('TERMINALS')
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
    local uri = vim.api.nvim_buf_get_name(buf)
    local pid = uri:match('^term://.-//(%d+):') or '?'
    add(
      '  buf=%d name=%s pid=%s job=%s wins=%s %s',
      buf,
      tostring(vim.b[buf].term_name),
      pid,
      tostring(vim.b[buf].terminal_job_id),
      vim.inspect(vim.fn.win_findbuf(buf)):gsub('%s+', ''),
      uri
    )
  end
end

return table.concat(out, '\n')
