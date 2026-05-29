local prettier_configs = {
  '.prettierrc',
  '.prettierrc.json',
  '.prettierrc.json5',
  '.prettierrc.yml',
  '.prettierrc.yaml',
  '.prettierrc.toml',
  '.prettierrc.js',
  '.prettierrc.cjs',
  '.prettierrc.mjs',
  'prettier.config.js',
  'prettier.config.cjs',
  'prettier.config.mjs',
}

vim.lsp.config['oxfmt'] = {
  cmd = { 'oxfmt', '--lsp' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
    'json',
    'jsonc',
    'yaml',
    'html',
    'css',
    'scss',
    'less',
    'markdown',
    'graphql',
  },
  root_dir = function(bufnr, on_dir)
    local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
    root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root_markers, { '.git' } }
      or vim.list_extend(root_markers, { '.git' })

    -- exclude deno
    if vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' }) then
      return
    end

    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

    -- exclude projects with any prettier config (use prettierd via none-ls instead)
    for _, name in ipairs(prettier_configs) do
      if vim.uv.fs_stat(project_root .. '/' .. name) then
        return
      end
    end

    on_dir(project_root)
  end,
}

vim.lsp.enable('oxfmt')
