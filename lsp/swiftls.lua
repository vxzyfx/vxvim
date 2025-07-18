---@brief
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- Language server for Swift and C/C++/Objective-C.

return {
  cmd = { 'sourcekit-lsp' },
  filetypes = { 'swift', 'objc', 'objcpp' },
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    on_dir(
      VxUtil.lsp.root_pattern 'buildServer.json' (filename)
      or VxUtil.lsp.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      -- better to keep it at the end, because some modularized apps contain multiple Package.swift files
      or VxUtil.lsp.root_pattern('compile_commands.json', 'Package.swift')(filename)
      or vim.fs.dirname(vim.fs.find('.git', { path = filename, upward = true })[1])
    )
  end,
  get_language_id = function(_, ftype)
    local t = { objc = 'objective-c', objcpp = 'objective-cpp' }
    return t[ftype] or ftype
  end,
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
  capabilities = vim.tbl_deep_extend("force", vim.deepcopy(VxUtil.lsp.capabilities), {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
    textDocument = {
      diagnostic = {
        dynamicRegistration = true,
        relatedDocumentSupport = true,
      },
    },
  }),
}
