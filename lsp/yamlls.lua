return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'yaml.helm-values' },
  root_markers = { '.git' },
  before_init = function(_, config)
    config.settings.yaml.schemas = vim.tbl_deep_extend(
      "force",
      config.settings.yaml.schemas or {},
      require("schemastore").yaml.schemas(),
      {
        ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.33.2/all.json"] = { "*.k8s.yaml", "*.k8s.yml" },
      }
    )
  end,
  capabilities = vim.tbl_deep_extend("force", vim.deepcopy(VxUtil.lsp.capabilities), {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  }),
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      keyOrdering = false,
      format = {
        enable = true,
      },
      validate = true,
      schemaStore = {
        enable = false,
        url = "",
      },
    },
  },
}
