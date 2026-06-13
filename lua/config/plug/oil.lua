local oil = require('oil')
local monitor = require('config.monitor')

-- Fraction of a single monitor the float should take. Oil resolves max_width/max_height
-- against the whole editor (both monitors), so the width is re-resolved in `override`
-- below; max_height still works as-is because monitors are side by side.
local WIDTH = 0.7

local pickerinclude_cache = {}

local function normalize_path(path)
  return vim.fs.normalize(path):gsub('/+$', '')
end

local function path_contains(parent, child)
  parent = normalize_path(parent)
  child = normalize_path(child)
  return child == parent or vim.startswith(child, parent .. '/')
end

local function get_pickerinclude_paths(root)
  local include_file = vim.fs.joinpath(root, '.pickerinclude')
  local stat = vim.uv.fs_stat(include_file)

  if stat == nil then
    pickerinclude_cache[root] = nil
    return nil
  end

  local cache_key = string.format('%s:%s', stat.mtime.sec, stat.mtime.nsec)
  local cached = pickerinclude_cache[root]
  if cached and cached.key == cache_key then
    return cached.paths
  end

  local paths = {}
  for line in io.lines(include_file) do
    line = vim.trim(line)
    if line ~= '' then
      paths[#paths + 1] = normalize_path(vim.fs.joinpath(root, line))
    end
  end

  pickerinclude_cache[root] = { key = cache_key, paths = paths }
  return paths
end

local function is_outside_pickerinclude(name, bufnr)
  if name == '..' then
    return false
  end

  local dir = oil.get_current_dir(bufnr)
  if dir == nil then
    return false
  end

  local root = vim.fs.root(dir, '.git')
  if root == nil then
    return false
  end

  local include_paths = get_pickerinclude_paths(root)
  if include_paths == nil then
    return false
  end

  local entry_path = normalize_path(vim.fs.joinpath(dir, name))
  for _, include_path in ipairs(include_paths) do
    if path_contains(include_path, entry_path) or path_contains(entry_path, include_path) then
      return false
    end
  end

  return true
end

local function add_cs_meta_oil_actions(actions)
  local util = require('oil.util')
  local fs = require('oil.fs')
  local cache = require('oil.cache')

  local function is_cs_file(url)
    return type(url) == 'string' and url:sub(-3) == '.cs'
  end

  local function ensure_existing_local_file(url)
    local scheme, path = util.parse_url(url)
    if scheme ~= 'oil://' or path == nil then
      return false
    end

    local stat = vim.uv.fs_stat(fs.posix_to_os_path(path))
    if stat == nil or stat.type ~= 'file' then
      return false
    end

    -- Oil updates its internal cache after every action. If the .meta file was hidden or
    -- otherwise not cached, seed it so Oil can update the cache without erroring.
    if cache.get_entry_by_url(url) == nil then
      local parent_url = scheme .. vim.fn.fnamemodify(path, ':h')
      local name = vim.fn.fnamemodify(path, ':t')
      cache.create_and_store_entry(parent_url, name, 'file')
    end

    return true
  end

  local deleting = {}
  local moving = {}
  for _, action in ipairs(actions) do
    if action.type == 'delete' then
      deleting[action.url] = true
    elseif action.type == 'move' then
      moving[action.src_url] = true
    end
  end

  local extra_actions = {}
  for _, action in ipairs(actions) do
    if action.entry_type == 'file' then
      if action.type == 'delete' and is_cs_file(action.url) then
        local meta_url = action.url .. '.meta'
        if not deleting[meta_url] and ensure_existing_local_file(meta_url) then
          extra_actions[#extra_actions + 1] = {
            type = 'delete',
            url = meta_url,
            entry_type = 'file',
          }
          deleting[meta_url] = true
        end
      elseif action.type == 'move' and is_cs_file(action.src_url) then
        local src_meta_url = action.src_url .. '.meta'
        local dest_meta_url = action.dest_url .. '.meta'
        if not moving[src_meta_url] and ensure_existing_local_file(src_meta_url) then
          extra_actions[#extra_actions + 1] = {
            type = 'move',
            src_url = src_meta_url,
            dest_url = dest_meta_url,
            entry_type = 'file',
          }
          moving[src_meta_url] = true
        end
      end
    end
  end

  vim.list_extend(actions, extra_actions)
end

pcall(vim.api.nvim_del_augroup_by_name, 'OilCsMetaActions')

local mutator = require('oil.mutator')
if not mutator._cs_meta_actions_patched then
  mutator._cs_meta_actions_patched = true
  local process_actions = mutator.process_actions
  mutator.process_actions = function(actions, cb)
    add_cs_meta_oil_actions(actions)
    return process_actions(actions, cb)
  end
end

oil.setup({
  view_options = {
    show_hidden = true,
    is_hidden_file = function(name)
      return name:match('^%.') ~= nil or name:match('%.meta$') ~= nil
    end,
    is_always_hidden = is_outside_pickerinclude,
  },
  float = {
    max_width = WIDTH,
    max_height = 0.7,
    -- Oil isn't a snacks picker, so it can't hook the shared picker layout; instead it
    -- exposes `override`, which gets the final window config just before the float is
    -- opened (while the current window is still the one '-' was pressed from). Re-anchor
    -- it onto one monitor with the same logic as the pickers and floats -- see
    -- config/monitor.lua.
    override = function(conf)
      local width = math.min(conf.width, math.floor(monitor.width() * WIDTH))
      conf.width = width
      -- -1 to match oil's own border adjustment: the border sits one col left of `col`.
      conf.col = monitor.centered_col(width) - 1
      return conf
    end,
  },
})

return oil
