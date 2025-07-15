return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zir' },
  root_markers = { 'zls.json', 'build.zig', '.git' },
  workspace_required = false,
  capabilities = vim.deepcopy(VxUtil.lsp.capabilities),
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
}
