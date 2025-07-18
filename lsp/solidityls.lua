---@brief
---
--- https://docs.soliditylang.org/en/latest/installing-solidity.html
---
--- solc is the native language server for the Solidity language.
return {
  cmd = { 'solc', '--lsp' },
  filetypes = { 'solidity' },
  root_markers = {
    'hardhat.config.js',
    'hardhat.config.ts',
    'foundry.toml',
    'remappings.txt',
    'truffle.js',
    'truffle-config.js',
    'ape-config.yaml',
    '.git',
    'package.json',
  },
  capabilities = vim.deepcopy(VxUtil.lsp.capabilities),
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
}
