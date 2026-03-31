vim.api.nvim_create_autocmd('User', {
  pattern = 'ClaudeStartBankSession',
  callback = function()
    local path = vim.g.claude_worktree_path
    local prompt = vim.g.claude_prompt
    local original_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    vim.cmd('tcd ' .. vim.fn.fnameescape(path))
    vim.wo.number = false
    vim.wo.relativenumber = false
    local job_id = vim.fn.termopen(vim.o.shell)
    vim.fn.chansend(job_id, 'claude ' .. vim.fn.shellescape(prompt) .. '\n')
    vim.api.nvim_set_current_tabpage(original_tab)
    _G.update_tab_branches()
  end,
})
