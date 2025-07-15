return {
  {
    "akinsho/flutter-tools.nvim",
    ft = "dart",
    opts = {
      debugger = {
        enabled = true,
      },
      lsp = {
        on_attach = function(client, bufnr)
          VxUtil.lsp.on_attach(client, bufnr)
          vim.keymap.set("n", "<leader>dr",
            "<Cmd>FlutterDebug<CR>",
            { desc = "Flutter Debug", buffer = bufnr })
        end
      },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
