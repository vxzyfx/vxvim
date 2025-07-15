return {
  cmd = { 'neocmakelsp', '--stdio' },
  filetypes = { 'cmake' },
  root_markers = { '.git', 'build', 'cmake' },
  capabilities = vim.deepcopy(VxUtil.lsp.capabilities),
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
}
