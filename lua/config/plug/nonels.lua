local nonels = require('null-ls')
local curl = require('plenary.curl')

local PORT = 6948
local URL = 'http://127.0.0.1:' .. PORT .. '/format'
local server_running = false

local csharpier_server = {
  name = 'csharpier server',
  method = nonels.methods.FORMATTING,
  filetypes = { 'cs' },
  generator = {
    fn = function(params)
      if not server_running then
        server_running = true
        vim.system({ 'csharpier', 'server', '--server-port', PORT }, { text = true })
        vim.notify('Started csharpier server')
      end

      local payload = {
        -- Remove the file:// prefix
        fileName = string.sub(params.lsp_params.textDocument.uri, 8),
        fileContents = table.concat(params.content, '\n'),
      }

      local ok, res = pcall(function()
        return curl.post({
          url = URL,
          body = vim.fn.json_encode(payload),
          headers = {
            ['Content-Type'] = 'application/json',
          },
        })
      end)

      if not ok or res.status ~= 200 then
        vim.notify('Request failed: ' .. res.status, vim.log.levels.INFO)
        return nil
      end

      local decodeOk, decoded = pcall(function()
        return vim.fn.json_decode(res.body)
      end)

      if not decodeOk or decoded.status == 'Failed' then
        vim.notify(decoded.errorMessage, vim.log.levels.INFO)
        return nil
      end

      return {
        {
          text = decoded.formattedFile,
        },
      }
    end,
  },
}

nonels.setup({
  sources = {
    csharpier_server,
    nonels.builtins.formatting.prettierd.with({
      env = {
        PRETTIERD_DEFAULT_CONFIG = vim.fn.expand('~/goblin-client-tools/.prettierrc.cjs'),
        PRETTIERD_LOCAL_PRETTIER_ONLY = 1,
      },
    }),
  },
})

return nonels
