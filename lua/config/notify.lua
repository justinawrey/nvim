local notify = vim.notify

-- Filter out some super annoying noisy messages that are causing
-- 'press enter' problems
vim.notify = function(msg, level, opts)
  if msg:match('no matching language servers') then
    return
  end

  notify(msg, level, opts)
end
