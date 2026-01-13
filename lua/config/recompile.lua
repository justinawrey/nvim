local uv = vim.loop
local md5 = vim.fn.sha256 -- built-in sha256

-- table to track hashes
local cs_dirty_table = {}
vim.g.any_cs_file_dirty = false

-- compute file hash
local function file_hash(path)
  local fd = uv.fs_open(path, 'r', 438) -- 438 = 0666
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return md5(data)
end

-- mark dirty files
local function check_dirty_cs(path)
  local hash = file_hash(path)
  -- indicates some sort of failure
  if hash == nil then
    vim.notify('Error creating file content hash for ' .. path)
    return false
  end

  -- no hash data for file, add latest hash
  if cs_dirty_table[path] == nil then
    cs_dirty_table[path] = hash
    return true
  end

  -- there was hash data, but new hash is different
  if cs_dirty_table[path] ~= hash then
    cs_dirty_table[path] = hash
    return true
  end
end

-- populate the dirty table if its empty
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.cs',
  callback = function(args)
    local path = vim.fn.expand(args.file)

    -- dont do anything if a hash is already populated
    -- for this file name
    if cs_dirty_table[path] ~= nil then
      return
    end

    -- otherwise 'pre-populate' it, which prevents initial
    -- saves from triggering a 'dirty' mark.  I tend to
    -- write alot so it happens
    local hash = file_hash(path)
    if hash == nil then
      vim.notify('Error during hash pre-population for ' .. path)
      return
    end

    cs_dirty_table[path] = hash
  end,
})

-- hook into BufWritePost
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.cs',
  callback = function(args)
    local path = vim.fn.expand(args.file)
    local dirty = check_dirty_cs(path)

    if dirty then
      vim.g.any_cs_file_dirty = true
    end
  end,
})

-- TODO: maybe need a port scan, idk its been ok.
-- I have this keymapped to <leader>rc
vim.api.nvim_create_user_command('UnityRecompile', function()
  vim.system({
    'curl',
    '-s',
    'http://127.0.0.1:51789/recompile',
  })
  vim.notify('Sent recompilation signal')
  vim.g.any_cs_file_dirty = false
  vim.api.nvim_command('redrawstatus')
end, {})
