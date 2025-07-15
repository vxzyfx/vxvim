return {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
  capabilities = vim.deepcopy(VxUtil.lsp.capabilities),
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
}
