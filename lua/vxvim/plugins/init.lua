require("vxvim.config").init()

return {
  { "folke/lazy.nvim", version = "*" },
  { "vxzyfx/vxvim", priority = 10000, lazy = false, opts = {}, cond = true, version = "*" },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {},
    config = function(_, opts)
      require("snacks").setup(opts)
    end,
  },
}
