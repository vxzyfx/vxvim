vim.uv = vim.uv or vim.loop

local M = {}

function M.setup(opts)
  require("vxvim.config").setup(opts)
end

return M
