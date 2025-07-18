_G.VxUtil = require("vxvim.util")
local M = {}

VxUtil.config = {
  -- icons used by other plugins
  -- stylua: ignore
  icons = {
    misc = {
      dots = "󰇘",
    },
    ft = {
      octo = "",
    },
    dap = {
      Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
      Breakpoint          = " ",
      BreakpointCondition = " ",
      BreakpointRejected  = { " ", "DiagnosticError" },
      LogPoint            = ".>",
    },
    diagnostics = {
      Error = " ",
      Warn  = " ",
      Hint  = " ",
      Info  = " ",
    },
    git = {
      added    = " ",
      modified = " ",
      removed  = " ",
    },
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Codeium       = "󰘦 ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Supermaven    = " ",
      TabNine       = "󰏚 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
  ---@type table<string, string[]|boolean>?
  kind_filter = {
    default = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      "Package",
      "Property",
      "Struct",
      "Trait",
    },
    markdown = false,
    help = false,
    -- you can specify a different filter for each filetype
    lua = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      -- "Package", -- remove package since luals uses it for control flow structures
      "Property",
      "Struct",
      "Trait",
    },
  },
  lsp_servers = { "astro", "basedpyright", "bashls", "clangd", "denols", "dockerls", "gopls", "jsonls", "luals",
    "neocmake",
    "nills",
    "tailwindcss", "vtsls", "vuels", "roslynls", "solidityls", "swiftls", "helmls", "yamlls", "zls" }
}

function M.setup(opts)
  local lazy_autocmds = vim.fn.argc(-1) == 0
  if not lazy_autocmds then
    M.load("autocmds")
  end

  local group = vim.api.nvim_create_augroup("VxVim", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    callback = function()
      if lazy_autocmds then
        M.load("autocmds")
      end
      M.load("keymaps")

      VxUtil.format.setup()
      VxUtil.root.setup()
      VxUtil.lsp.setup()
    end
  })
  VxUtil.track("colorscheme")
  VxUtil.try(function()
    -- require("tokyonight").load()
    vim.cmd.colorscheme("catppuccin")
  end, {
    msg = "Could not load your colorscheme",
    on_error = function(msg)
      VxUtil.error(msg)
      vim.cmd.colorscheme("habamax")
    end,
  })
  VxUtil.track()
end

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
  local function _load(mod)
    VxUtil.try(function()
      require(mod)
    end, { msg = "Failed loading " .. mod })
  end
  local pattern = "VxVim" .. name:sub(1, 1):upper() .. name:sub(2)
  _load("vxvim.config." .. name)
  vim.api.nvim_exec_autocmds("User", { pattern = pattern .. "Defaults", modeline = false })
  if vim.bo.filetype == "lazy" then
    vim.cmd([[do VimResized]])
  end
  vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
end

M.did_init = false
function M.init()
  if M.did_init then
    return
  end
  M.did_init = true
  VxUtil.lazy_notify()
  M.load("options")
  VxUtil.plugin.setup()
end

return M
