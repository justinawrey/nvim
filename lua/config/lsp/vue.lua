---@brief
---
--- https://github.com/vuejs/language-tools/tree/master/packages/language-server
---
--- The official language server for Vue
---
--- It can be installed via npm:
--- ```sh
--- npm install -g @vue/language-server
--- ```
---
--- The language server only supports Vue 3 projects by default.
--- For Vue 2 projects, [additional configuration](https://github.com/vuejs/language-tools/blob/master/extensions/vscode/README.md?plain=1#L19) are required.
---
--- The Vue language server works in "hybrid mode" that exclusively manages the CSS/HTML sections.
--- You need the `vtsls` server with the `@vue/typescript-plugin` plugin to support TypeScript in `.vue` files.
--- See `vtsls` section and https://github.com/vuejs/language-tools/wiki/Neovim for more information.
---
--- NOTE: Since v3.0.0, the Vue Language Server [no longer supports takeover mode](https://github.com/vuejs/language-tools/pull/5248).

-- `vue-language-server` needs a TypeScript with the programmatic JS API (it reads
-- `ts.server.protocol` to talk to vtsls). TypeScript 7 ships no such API, and npm
-- resolves the server's `typescript: "*"` peer to 7.x, which crashes the server with
-- `Cannot read properties of undefined (reading 'protocol')`. So point it explicitly at
-- the typescript@6 installed alongside it in ~/.local/lsp-servers.
local function vue_cmd()
  local cmd = { 'vue-language-server', '--stdio' }

  local exe = vim.fn.exepath('vue-language-server')
  if exe == '' then
    return cmd
  end

  -- .../lib/node_modules/@vue/language-server/bin/vue-language-server.js -> .../node_modules
  local bin = vim.uv.fs_realpath(exe) or exe
  local global_modules = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(bin))))
  local tsdk = global_modules .. '/typescript/lib'

  if vim.uv.fs_stat(tsdk .. '/typescript.js') then
    table.insert(cmd, '--tsdk=' .. tsdk)
  else
    vim.notify(
      'No TypeScript 6 tsdk found for vue-language-server. Install it with '
        .. '`npm --prefix ~/.local/lsp-servers i -g typescript@6`.',
      vim.log.levels.WARN
    )
  end

  return cmd
end

vim.lsp.config['vue'] = {
  cmd = vue_cmd(),
  filetypes = { 'vue' },
  root_markers = { 'package.json' },
  on_init = function(client)
    local retries = 0

    local function typescriptHandler(_, result, context)
      local ts_client = vim.lsp.get_clients({ bufnr = context.bufnr, name = 'ts' })[1]

      if not ts_client then
        -- there can sometimes be a short delay until `ts_ls`/`vtsls` are attached so we retry for a few times until it is ready
        if retries <= 10 then
          retries = retries + 1
          vim.defer_fn(function()
            typescriptHandler(_, result, context)
          end, 100)
        else
          vim.notify(
            'Could not find `ts_ls`, `vtsls`, or `typescript-tools` lsp client required by `vue_ls`.',
            vim.log.levels.ERROR
          )
        end
        return
      end

      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = 'vue_request_forward', -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
        command = 'typescript.tsserverRequest',
        arguments = {
          command,
          payload,
        },
      }, { bufnr = context.bufnr }, function(_, r)
        local response_data = { { id, r and r.body } }
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify('tsserver/response', response_data)
      end)
    end

    client.handlers['tsserver/request'] = typescriptHandler
  end,

  -- Ensure that vue language server doesnt format -- we wanna use prettierd
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

vim.lsp.enable('vue')
