local VxVim = require("vxvim.util")

---@class VxVimConfig: VxVimOptions
local M = {}

VxVim.config = M

---@class VxVimOptions
local defaults = {
  -- colorscheme can be a string like `catppuccin` or a function that will load the colorscheme
  ---@type string|fun()
  colorscheme = function()
    require("tokyonight").load()
  end,
  -- load the default settings
  defaults = {
    autocmds = true, -- vxvim.config.autocmds
    keymaps = true,  -- vxvim.config.keymaps
  },
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
}

---@type VxVimOptions
local options
local lazy_clipboard

---@param opts? VxVimOptions
function M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}

  -- autocmds can be loaded lazily when not opening a file
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
      if lazy_clipboard ~= nil then
        vim.opt.clipboard = lazy_clipboard
      end

      VxVim.format.setup()
      VxVim.root.setup()

      vim.api.nvim_create_user_command("LazyExtras", function()
        VxVim.extras.show()
      end, { desc = "Manage VxVim extras" })

      vim.api.nvim_create_user_command("LazyHealth", function()
        vim.cmd([[Lazy! load all]])
        vim.cmd([[checkhealth]])
      end, { desc = "Load all plugins and run :checkhealth" })

      local health = require("lazy.health")
      vim.list_extend(health.valid, {
        "recommended",
        "desc",
        "vscode",
      })

      if vim.g.vxvim_check_order == false then
        return
      end

      -- Check lazy.nvim import order
      local imports = require("lazy.core.config").spec.modules
      local function find(pat, last)
        for i = last and #imports or 1, last and 1 or #imports, last and -1 or 1 do
          if imports[i]:find(pat) then
            return i
          end
        end
      end
      local vxvim_plugins = find("^vxvim%.plugins$")
      local extras = find("^vxvim%.plugins%.extras%.", true) or vxvim_plugins
      local plugins = find("^plugins$") or math.huge
      if vxvim_plugins ~= 1 or extras > plugins then
        local msg = {
          "The order of your `lazy.nvim` imports is incorrect:",
          "- `vxvim.plugins` should be first",
          "- followed by any `vxvim.plugins.extras`",
          "- and finally your own `plugins`",
          "",
          "If you think you know what you're doing, you can disable this check with:",
          "```lua",
          "vim.g.vxvim_check_order = false",
          "```",
        }
        vim.notify(table.concat(msg, "\n"), "warn", { title = "VxVim" })
      end
    end,
  })

  VxVim.track("colorscheme")
  VxVim.try(function()
    if type(M.colorscheme) == "function" then
      M.colorscheme()
    else
      vim.cmd.colorscheme(M.colorscheme)
    end
  end, {
    msg = "Could not load your colorscheme",
    on_error = function(msg)
      VxVim.error(msg)
      vim.cmd.colorscheme("habamax")
    end,
  })
  VxVim.track()
end

---@param buf? number
---@return string[]?
function M.get_kind_filter(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local ft = vim.bo[buf].filetype
  if M.kind_filter == false then
    return
  end
  if M.kind_filter[ft] == false then
    return
  end
  if type(M.kind_filter[ft]) == "table" then
    return M.kind_filter[ft]
  end
  ---@diagnostic disable-next-line: return-type-mismatch
  return type(M.kind_filter) == "table" and type(M.kind_filter.default) == "table" and M.kind_filter.default or nil
end

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
  local function _load(mod)
    if require("lazy.core.cache").find(mod)[1] then
      VxVim.try(function()
        require(mod)
      end, { msg = "Failed loading " .. mod })
    end
  end
  local pattern = "VxVim" .. name:sub(1, 1):upper() .. name:sub(2)
  -- always load vxvim, then user file
  if M.defaults[name] or name == "options" then
    _load("vxvim.config." .. name)
    vim.api.nvim_exec_autocmds("User", { pattern = pattern .. "Defaults", modeline = false })
  end
  _load("config." .. name)
  if vim.bo.filetype == "lazy" then
    -- HACK: VxVim may have overwritten options of the Lazy ui, so reset this here
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
  local plugin = require("lazy.core.config").spec.plugins.VxVim
  if plugin then
    vim.opt.rtp:append(plugin.dir)
  end

  package.preload["vxvim.plugins.lsp.format"] = function()
    VxVim.deprecate([[require("vxvim.plugins.lsp.format")]], [[VxVim.format]])
    return VxVim.format
  end

  -- delay notifications till vim.notify was replaced or after 500ms
  VxVim.lazy_notify()

  -- load options here, before lazy init while sourcing plugin modules
  -- this is needed to make sure options will be correctly applied
  -- after installing missing plugins
  M.load("options")
  -- defer built-in clipboard handling: "xsel" and "pbcopy" can be slow
  lazy_clipboard = vim.opt.clipboard
  vim.opt.clipboard = ""

  if vim.g.deprecation_warnings == false then
    vim.deprecate = function() end
  end

  VxVim.plugin.setup()
end

---@alias VxVimDefault {name: string, extra: string, enabled?: boolean, origin?: "global" | "default" | "extra" }

local default_extras ---@type table<string, VxVimDefault>
function M.get_defaults()
  if default_extras then
    return default_extras
  end
  ---@type table<string, VxVimDefault[]>
  local checks = {
    picker = {
      { name = "snacks",    extra = "editor.snacks_picker" },
      { name = "fzf",       extra = "editor.fzf" },
      { name = "telescope", extra = "editor.telescope" },
    },
    cmp = {
      { name = "blink.cmp", extra = "coding.blink",   enabled = vim.fn.has("nvim-0.10") == 1 },
      { name = "nvim-cmp",  extra = "coding.nvim-cmp" },
    },
    explorer = {
      { name = "snacks",   extra = "editor.snacks_explorer" },
      { name = "neo-tree", extra = "editor.neo-tree" },
    },
  }

  default_extras = {}
  for name, check in pairs(checks) do
    local valid = {} ---@type string[]
    for _, extra in ipairs(check) do
      if extra.enabled ~= false then
        valid[#valid + 1] = extra.name
      end
    end
    local origin = "default"
    local use = vim.g["vxvim_" .. name]
    use = vim.tbl_contains(valid, use or "auto") and use or nil
    origin = use and "global" or origin
    for _, extra in ipairs(use and {} or check) do
      if extra.enabled ~= false and VxVim.has_extra(extra.extra) then
        use = extra.name
        break
      end
    end
    origin = use and "extra" or origin
    use = use or valid[1]
    for _, extra in ipairs(check) do
      local import = "vxvim.plugins.extras." .. extra.extra
      extra = vim.deepcopy(extra)
      extra.enabled = extra.name == use
      if extra.enabled then
        extra.origin = origin
      end
      default_extras[import] = extra
    end
  end
  return default_extras
end

setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    ---@cast options VxVimConfig
    return options[key]
  end,
})

return M
