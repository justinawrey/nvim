local tab_branches = {}
local tab_repos = {}
local tab_notifications = {}
local tab_spinning = {}

-- Spinner animation
local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local spinner_index = 1
local spinner_timer = nil

local function ensure_spinner_timer()
  if spinner_timer then return end
  spinner_timer = vim.uv.new_timer()
  spinner_timer:start(0, 80, vim.schedule_wrap(function()
    spinner_index = (spinner_index % #spinner_frames) + 1
    vim.cmd('redrawtabline')
  end))
end

local function maybe_stop_spinner_timer()
  for _, v in pairs(tab_spinning) do
    if v then return end
  end
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
end

local repo_short_names = {
  firespotter = 'fs',
  ['goblin-client-tools'] = 'gct',
  dialtone = 'dt',
  ['web-clients'] = 'wc',
}

-- Create an alternate TabLine highlight with a slightly different background
-- so adjacent tabs are easier to distinguish.
local function setup_tabline_alt_hl()
  local hl = vim.api.nvim_get_hl(0, { name = 'TabLine', link = false })
  local bg = hl.bg
  if not bg then return end
  -- Darken the background by a small amount
  local r = math.max(0, bit.rshift(bit.band(bg, 0xFF0000), 16) - 12)
  local g = math.max(0, bit.rshift(bit.band(bg, 0x00FF00), 8) - 12)
  local b = math.max(0, bit.band(bg, 0x0000FF) - 12)
  vim.api.nvim_set_hl(0, 'TabLineAlt', { fg = hl.fg, bg = r * 0x10000 + g * 0x100 + b })
end

setup_tabline_alt_hl()
vim.api.nvim_create_autocmd('ColorScheme', { callback = setup_tabline_alt_hl })

local function get_tab_info(tabnr)
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

  vim.system({ 'git', '-C', cwd, 'remote', 'get-url', 'origin' }, { text = true }, function(result)
    local url = vim.trim(result.stdout or '')
    local repo = url:match('.*/(.+)%.git$') or url:match('.*/(.+)$')
    if repo and repo ~= '' then
      tab_repos[tabnr] = repo_short_names[repo] or repo
    else
      tab_repos[tabnr] = nil
    end
    vim.schedule(function()
      vim.cmd('redrawtabline')
    end)
  end)
end

function _G.update_tab_branches()
  -- Clear stale entries from closed/renumbered tabs before repopulating.
  -- Without this, closing a tab leaves its old branch name keyed under
  -- the old tab number, which can briefly display on a renumbered tab
  -- (making it look like a duplicate).
  local n = vim.fn.tabpagenr('$')
  for k in pairs(tab_branches) do
    if k > n then
      tab_branches[k] = nil
    end
  end
  for k in pairs(tab_repos) do
    if k > n then
      tab_repos[k] = nil
    end
  end
  for k in pairs(tab_notifications) do
    if k > n then
      tab_notifications[k] = nil
    end
  end
  for k in pairs(tab_spinning) do
    if k > n then
      tab_spinning[k] = nil
    end
  end
  for i = 1, n do
    get_tab_info(i)
  end
end

vim.api.nvim_create_autocmd({ 'TabEnter', 'TabNew', 'TabClosed', 'DirChanged', 'FocusGained' }, {
  callback = update_tab_branches,
})

-- Initial population
update_tab_branches()

-- Mark a tab as needing attention based on its CWD.
function _G.mark_tab_attention(cwd)
  local resolve = vim.uv.fs_realpath
  local resolved_target = resolve(cwd) or cwd
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local tab_cwd = resolve(vim.fn.getcwd(-1, tabnr)) or vim.fn.getcwd(-1, tabnr)
    if tab_cwd == resolved_target then
      tab_notifications[tabnr] = true
      vim.schedule(function()
        vim.cmd('redrawtabline')
      end)
      return ''
    end
  end
  return ''
end

-- Called from Claude Code's Notification hook via --remote-expr.
-- Reads the target CWD from the file to avoid shell escaping issues.
function _G.mark_tab_attention_from_file()
  local f = io.open(vim.fn.expand('~/.claude/last_notification_cwd'), 'r')
  if not f then return '' end
  local cwd = f:read('*a'):gsub('%s+$', '')
  f:close()
  if cwd ~= '' then
    return _G.mark_tab_attention(cwd)
  end
  return ''
end

-- Clear the notification dot for the tab matching a CWD.
function _G.clear_tab_attention(cwd)
  local resolve = vim.uv.fs_realpath
  local resolved_target = resolve(cwd) or cwd
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local tab_cwd = resolve(vim.fn.getcwd(-1, tabnr)) or vim.fn.getcwd(-1, tabnr)
    if tab_cwd == resolved_target then
      tab_notifications[tabnr] = nil
      vim.schedule(function()
        vim.cmd('redrawtabline')
      end)
      return ''
    end
  end
  return ''
end

-- Called from the UserPromptSubmit hook via --remote-expr.
function _G.clear_tab_attention_from_file()
  local f = io.open(vim.fn.expand('~/.claude/last_clear_cwd'), 'r')
  if not f then return '' end
  local cwd = f:read('*a'):gsub('%s+$', '')
  f:close()
  if cwd ~= '' then
    return _G.clear_tab_attention(cwd)
  end
  return ''
end

-- Start a thinking spinner on the tab matching a CWD.
function _G.start_tab_spinner(cwd)
  local resolve = vim.uv.fs_realpath
  local resolved_target = resolve(cwd) or cwd
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local tab_cwd = resolve(vim.fn.getcwd(-1, tabnr)) or vim.fn.getcwd(-1, tabnr)
    if tab_cwd == resolved_target then
      tab_spinning[tabnr] = true
      tab_notifications[tabnr] = nil
      vim.schedule(function()
        ensure_spinner_timer()
        vim.cmd('redrawtabline')
      end)
      return ''
    end
  end
  return ''
end

-- Called from the UserPromptSubmit hook via --remote-expr.
function _G.start_tab_spinner_from_file()
  local f = io.open(vim.fn.expand('~/.claude/last_spinner_cwd'), 'r')
  if not f then return '' end
  local cwd = f:read('*a'):gsub('%s+$', '')
  f:close()
  if cwd ~= '' then
    return _G.start_tab_spinner(cwd)
  end
  return ''
end

-- Stop the thinking spinner on the tab matching a CWD.
function _G.stop_tab_spinner(cwd)
  local resolve = vim.uv.fs_realpath
  local resolved_target = resolve(cwd) or cwd
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local tab_cwd = resolve(vim.fn.getcwd(-1, tabnr)) or vim.fn.getcwd(-1, tabnr)
    if tab_cwd == resolved_target then
      tab_spinning[tabnr] = nil
      vim.schedule(function()
        maybe_stop_spinner_timer()
        vim.cmd('redrawtabline')
      end)
      return ''
    end
  end
  return ''
end

-- Called from the Stop/Notification hooks via --remote-expr.
function _G.stop_tab_spinner_from_file()
  local f = io.open(vim.fn.expand('~/.claude/last_spinner_stop_cwd'), 'r')
  if not f then return '' end
  local cwd = f:read('*a'):gsub('%s+$', '')
  f:close()
  if cwd ~= '' then
    return _G.stop_tab_spinner(cwd)
  end
  return ''
end

function _G.custom_tabline()
  local s = ''

  for i = 1, vim.fn.tabpagenr('$') do
    -- select the highlighting
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    elseif i % 2 == 0 then
      s = s .. '%#TabLineAlt#'
    else
      s = s .. '%#TabLine#'
    end

    local label = tab_branches[i] or tostring(i)
    if tab_repos[i] then
      label = label .. ' [' .. tab_repos[i] .. ']'
    end
    if tab_notifications[i] then
      label = label .. ' ●'
    elseif tab_spinning[i] then
      label = label .. ' ' .. spinner_frames[spinner_index]
    end
    s = s .. ' ' .. label .. ' '
  end

  return s
end

-- Tabline
vim.opt.tabline = '%= %{%v:lua.custom_tabline()%}'
