return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'vue',
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json', '.git' },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.g.vx_ts_vue_location,
            languages = { "vue" },
            configNamespace = "typescript",
            enableForWorkspaceTypeScriptVersions = true,
          },
        }
      }
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
  },
  capabilities = vim.deepcopy(VxUtil.lsp.capabilities),
  on_attach = function(client, bufnr)
    client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
      ---@type string, string, lsp.Range
      local action, uri, range = unpack(command.arguments)

      local function move(newf)
        client.request("workspace/executeCommand", {
          command = command.command,
          arguments = { action, uri, range, newf },
        })
      end

      local fname = vim.uri_to_fname(uri)
      client.request("workspace/executeCommand", {
        command = "typescript.tsserverRequest",
        arguments = {
          "getMoveToRefactoringFileSuggestions",
          {
            file = fname,
            startLine = range.start.line + 1,
            startOffset = range.start.character + 1,
            endLine = range["end"].line + 1,
            endOffset = range["end"].character + 1,
          },
        },
      }, function(_, result)
        ---@type string[]
        local files = result.body.files
        table.insert(files, 1, "Enter new path...")
        vim.ui.select(files, {
          prompt = "Select move destination:",
          format_item = function(f)
            return vim.fn.fnamemodify(f, ":~:.")
          end,
        }, function(f)
          if f and f:find("^Enter new path") then
            vim.ui.input({
              prompt = "Enter move destination:",
              default = vim.fn.fnamemodify(fname, ":h") .. "/",
              completion = "file",
            }, function(newf)
              return newf and move(newf)
            end)
          elseif f then
            move(f)
          end
        end)
      end)
    end
    VxUtil.lsp.on_attach(client, bufnr)
    vim.keymap.set("n", "gD", function()
        local params = vim.lsp.util.make_position_params()
        VxUtil.lsp.execute({
          command = "typescript.goToSourceDefinition",
          arguments = { params.textDocument.uri, params.position },
          open = true,
        })
      end,
      { desc = "Goto Source Definition", buffer = bufnr })
    vim.keymap.set("n", "gR", function()
        VxUtil.lsp.execute({
          command = "typescript.findAllFileReferences",
          arguments = { vim.uri_from_bufnr(0) },
          open = true,
        })
      end,
      { desc = "File References", buffer = bufnr })
    vim.keymap.set("n", "<leader>co", VxUtil.lsp.action["source.organizeImports"],
      { desc = "Organize Imports", buffer = bufnr })
    vim.keymap.set("n", "<leader>cM", VxUtil.lsp.action["source.addMissingImports.ts"],
      { desc = "Add missing imports", buffer = bufnr })
    vim.keymap.set("n", "<leader>cu", VxUtil.lsp.action["source.removeUnused.ts"],
      { desc = "Remove unused imports", buffer = bufnr })
    vim.keymap.set("n", "<leader>cD", VxUtil.lsp.action["source.fixAll.ts"],
      { desc = "Fix all diagnostics", buffer = bufnr })
    vim.keymap.set("n", "<leader>cV",
      function()
        VxUtil.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
      end,
      { desc = "Select TS workspace version", buffer = bufnr })
  end,
}
