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

local function get_pickerinclude_dirs(root)
  local include_file = vim.fs.joinpath(root, '.pickerinclude')
  local stat = vim.uv.fs_stat(include_file)

  if stat == nil then
    pickerinclude_cache[root] = nil
    return nil
  end

  local cache_key = string.format('%s:%s', stat.mtime.sec, stat.mtime.nsec)
  local cached = pickerinclude_cache[root]
  if cached and cached.key == cache_key then
    return cached.dirs
  end

  local dirs = {}
  for line in io.lines(include_file) do
    line = vim.trim(line)
    if line ~= '' then
      dirs[#dirs + 1] = normalize_path(vim.fs.joinpath(root, line))
    end
  end

  pickerinclude_cache[root] = { key = cache_key, dirs = dirs }
  return dirs
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

  local include_dirs = get_pickerinclude_dirs(root)
  if include_dirs == nil then
    return false
  end

  local entry_path = normalize_path(vim.fs.joinpath(dir, name))
  for _, include_dir in ipairs(include_dirs) do
    if path_contains(include_dir, entry_path) or path_contains(entry_path, include_dir) then
      return false
    end
  end

  return true
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
