return {
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    config = function()
      require("kotlin").setup()
    end,
  },
}
