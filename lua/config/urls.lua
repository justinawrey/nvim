-- Open URLs from any buffer -- including nvim's :terminal -- without a mouse.
--
-- Ghostty's own cmd+click link detection technically works over top of nvim, but it's
-- mouse-only and it fights with nvim's redraws. This scans the buffer text instead, so
-- it works identically in a terminal buffer, a file, or a scrollback.
--
-- Keymaps (set at the bottom):
--   <leader>u  normal mode  -- pick a URL from the current buffer
--   <C-g>      terminal mode -- same, without having to jj out first

local M = {}

-- Scheme'd URLs plus bare www.* hosts. The character class is deliberately greedy;
-- trailing junk is trimmed in `clean` below.
local PATTERNS = {
  '%a[%w+.%-]*://[%w%-_.~:/?#%[%]@!$&\'()*+,;=%%]+',
  'www%.[%w%-_.~:/?#%[%]@!$&\'()*+,;=%%]+',
}

-- Terminals hard-wrap long URLs at the window edge and nvim stores each screen row as
-- its own buffer line, so a wrapped URL arrives split across two lines. Glue those back
-- together before scanning.
--
-- The wrap column is *not* the current window width: the buffer holds output rendered at
-- whatever width the window had at the time, and it may have been resized since. The
-- widest line actually present is a much better estimate, since no line can exceed the
-- wrap column. Widths are measured in display cells, not bytes -- shell prompts are full
-- of multi-byte powerline glyphs that would otherwise look "full width".
--
-- A join needs the line to reach the wrap column *and* the next line to start without
-- whitespace, so wrapped prose (which breaks on spaces) is left alone.
local function unwrap(lines)
  local wrapcol = 0
  for _, line in ipairs(lines) do
    wrapcol = math.max(wrapcol, vim.fn.strdisplaywidth(line))
  end
  if wrapcol < 20 then
    return lines
  end

  local out = {}
  -- Display width of the last *physical* row appended, not of the accumulated join: a
  -- joined line is always over the wrap column, which would otherwise make every
  -- following unindented row look like a continuation.
  local prev_width = 0
  for _, line in ipairs(lines) do
    local width = vim.fn.strdisplaywidth(line)
    if #out > 0 and prev_width >= wrapcol and line ~= '' and not line:match('^%s') then
      out[#out] = out[#out] .. line
    else
      out[#out + 1] = line
    end
    prev_width = width
  end
  return out
end

-- Strip the punctuation that commonly hugs a URL in prose/logs but isn't part of it:
-- a trailing period/comma/colon, and unbalanced closing brackets or quotes.
local function clean(url)
  url = url:gsub('[%.,;:!?]+$', '')
  for open, close in pairs({ ['('] = ')', ['['] = ']', ['{'] = '}' }) do
    while url:sub(-1) == close do
      local _, opens = url:gsub('%' .. open, '')
      local _, closes = url:gsub('%' .. close, '')
      if closes <= opens then
        break
      end
      url = url:sub(1, -2)
    end
  end
  return (url:gsub('[\'"`>]+$', ''))
end

-- Every URL in `buf`, most recently written first (terminal output grows downward, so
-- the bottom of the buffer is what you almost always want). Deduped.
function M.collect(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.bo[buf].buftype == 'terminal' then
    lines = unwrap(lines)
  end

  local urls, seen = {}, {}
  for i = #lines, 1, -1 do
    for _, pattern in ipairs(PATTERNS) do
      for match in lines[i]:gmatch(pattern) do
        local url = clean(match)
        if #url > 0 and not seen[url] then
          seen[url] = true
          urls[#urls + 1] = url
        end
      end
    end
  end
  return urls
end

-- Pick a URL and hand it to the OS. One hit opens straight away; several show a picker.
function M.pick()
  local urls = M.collect(0)

  if #urls == 0 then
    vim.notify('No URLs in this buffer', vim.log.levels.WARN)
    return
  end

  if #urls == 1 then
    vim.notify('Opening ' .. urls[1])
    vim.ui.open(urls[1])
    return
  end

  local items = {}
  for i, url in ipairs(urls) do
    items[#items + 1] = { idx = i, score = 0, text = url, url = url }
  end

  Snacks.picker({
    title = 'URLs',
    items = items,
    -- Keep insertion order (newest output first) instead of fuzzy-sorting by default.
    sort = function()
      return false
    end,
    format = function(item)
      return { { item.url, 'SnacksPickerLink' } }
    end,
    preview = 'none',
    layout = { preset = 'vscode' },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.ui.open(item.url)
      end
    end,
  })
end

vim.keymap.set('n', '<leader>u', M.pick, { desc = 'Open a URL from this buffer' })

-- Terminal mode gets a control key: <leader> is space, which you obviously can't shadow
-- while typing into a shell. <C-g> is otherwise unbound and rarely meaningful to a TUI.
vim.keymap.set('t', '<C-g>', function()
  M.pick()
end, { desc = 'Open a URL from this terminal' })

return M
