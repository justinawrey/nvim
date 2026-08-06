---@brief
---
--- https://github.com/yioneko/vtsls
---
--- `vtsls` can be installed with npm:
--- ```sh
--- npm install -g @vtsls/language-server
--- ```
---
--- To configure a TypeScript project, add a
--- [`tsconfig.json`](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html)
--- or [`jsconfig.json`](https://code.visualstudio.com/docs/languages/jsconfig) to
--- the root of your project.
---
--- ### Vue support
---
--- Since v3.0.0, the Vue language server requires `vtsls` to support TypeScript.
---
--- ```
--- -- If you are using mason.nvim, you can get the ts_plugin_path like this
--- -- For Mason v1,
--- -- local mason_registry = require('mason-registry')
--- -- local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'
--- -- For Mason v2,
--- -- local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'
--- -- or even

--- vim.lsp.config('vtsls', {
---   settings = {
---     vtsls = {
---       tsserver = {
---         globalPlugins = {
---           vue_plugin,
---         },
---       },
---     },
---   },
---   filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
--- })
--- ```
---
--- - `location` MUST be defined. If the plugin is installed in `node_modules`, `location` can have any value.
--- - `languages` must include vue even if it is listed in filetypes.
--- - `filetypes` is extended here to include Vue SFC.
---
--- You must make sure the Vue language server is setup. For example,
---
--- ```
--- vim.lsp.enable('vue_ls')
--- ```
---
--- See `vue_ls` section and https://github.com/vuejs/language-tools/wiki/Neovim for more information.
---
--- ### Monorepo support
---
--- `vtsls` supports monorepos by default. It will automatically find the `tsconfig.json` or `jsconfig.json` corresponding to the package you are working on.
--- This works without the need of spawning multiple instances of `vtsls`, saving memory.
---
--- It is recommended to use the same version of TypeScript in all packages, and therefore have it available in your workspace root. The location of the TypeScript binary will be determined automatically, but only once.

-- Resolve `@vue/typescript-plugin` from wherever `vue-language-server` is installed.
--
-- The language servers live in their own npm prefix, outside of fnm, so that switching
-- node versions (or `--use-on-cd` picking up a repo's .nvmrc) doesn't make them vanish:
--
--   npm --prefix ~/.local/lsp-servers i -g @vtsls/language-server \
--     @vue/language-server vscode-langservers-extracted typescript@6
--
-- with `~/.local/lsp-servers/bin` appended to PATH in ~/.zshrc. The bins are
-- `#!/usr/bin/env node`, so they still run under whatever node fnm has active.
-- Derive the path rather than hardcoding it so upgrades don't break the config.
local function vue_plugin_location()
  local exe = vim.fn.exepath('vue-language-server')
  if exe == '' then
    return nil
  end

  -- .../lib/node_modules/@vue/language-server/bin/vue-language-server.js
  local bin = vim.uv.fs_realpath(exe) or exe
  -- .../lib/node_modules/@vue/language-server
  local pkg_root = vim.fs.dirname(vim.fs.dirname(bin))
  local location = pkg_root .. '/node_modules'

  if vim.uv.fs_stat(location .. '/@vue/typescript-plugin') == nil then
    return nil
  end

  return location
end

local location = vue_plugin_location()
if not location then
  vim.notify(
    'Could not locate `@vue/typescript-plugin`. Install it with '
      .. '`npm --prefix ~/.local/lsp-servers i -g @vue/language-server`.',
    vim.log.levels.WARN
  )
end

local vue_plugin = location
    and {
      name = '@vue/typescript-plugin',
      location = location,
      languages = { 'vue' },
      configNamespace = 'typescript',
    }
  or nil

vim.lsp.config['ts'] = {
  cmd = { 'vtsls', '--stdio' },
  init_options = {
    hostInfo = 'neovim',
  },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    },
  },
  filetypes = {
    'vue',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  root_dir = function(bufnr, on_dir)
    -- The project root is where the LSP can be started from
    -- As stated in the documentation above, this LSP supports monorepos and simple projects.
    -- We select then from the project root, which is identified by the presence of a package
    -- manager lock file.
    local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
    -- Give the root markers equal priority by wrapping them in a table
    root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root_markers, { '.git' } }
      or vim.list_extend(root_markers, { '.git' })

    -- We fallback to the current working directory if no project root is found
    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

    on_dir(project_root)
  end,

  -- Ensure that vtsls doesnt format -- we wanna use prettier via none-ls
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

vim.lsp.enable('ts')
