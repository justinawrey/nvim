vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd('enew') -- New empty buffer
      vim.bo.buftype = 'nofile'
      vim.bo.bufhidden = 'wipe'
      vim.bo.swapfile = false
      vim.bo.filetype = 'justin_welcome'

      -- Attach custom data
      local buf = vim.api.nvim_get_current_buf()

      vim.b[buf].is_welcome = true

      -- The lines of your welcome screen
      local lines = {
        'Welcome to Neovim, Justin!',
      }

      local width = vim.api.nvim_win_get_width(0)
      local height = vim.api.nvim_win_get_height(0)

      -- Horizontally center each line
      for i, line in ipairs(lines) do
        local padding = math.floor((width - vim.fn.strdisplaywidth(line)) / 2)
        lines[i] = string.rep(' ', math.max(padding, 0)) .. line
      end

      -- Vertically center by adding empty lines at the top
      local top_padding = math.floor((height - #lines) / 2)
      for _ = 1, top_padding do
        table.insert(lines, 1, '')
      end

      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      vim.cmd('setlocal nomodifiable')
      vim.cmd('setlocal nonumber norelativenumber') -- optional, for clean look
    end
  end,
})
