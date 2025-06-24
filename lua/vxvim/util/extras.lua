local VxVim = require("vxvim.util")
local Float = require("lazy.view.float")
local LazyConfig = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Text = require("lazy.view.text")

---@class LazyExtraSource
---@field name string
---@field desc? string
---@field module string

---@class LazyExtra
---@field name string
---@field source LazyExtraSource
---@field module string
---@field desc? string
---@field enabled boolean
---@field managed boolean
---@field recommended? boolean
---@field imports string[]
---@field row? number
---@field section? string
---@field plugins string[]
---@field optional string[]

---@class vxvim.util.extras
local M = {}
M.buf = 0

---@type LazyExtraSource[]
M.sources = {
  { name = "VxVim", desc = "VxVim extras", module = "vxvim.plugins.extras" },
  { name = "User",  desc = "User extras",  module = "plugins.extras" },
}

M.ns = vim.api.nvim_create_namespace("vxvim.extras")
---@type string[]
M.state = nil

---@alias WantsOpts {ft?: string|string[], root?: string|string[]}

---@param opts WantsOpts
---@return boolean
function M.wants(opts)
  if opts.ft then
    opts.ft = type(opts.ft) == "string" and { opts.ft } or opts.ft
    for _, f in ipairs(opts.ft) do
      if vim.bo[M.buf].filetype == f then
        return true
      end
    end
  end
  if opts.root then
    opts.root = type(opts.root) == "string" and { opts.root } or opts.root
    return #VxVim.root.detectors.pattern(M.buf, opts.root) > 0
  end
  return false
end

---@return LazyExtra[]
function M.get()
  M.state = M.state or LazyConfig.spec.modules
  local extras = {} ---@type LazyExtra[]
  for _, source in ipairs(M.sources) do
    local root = VxVim.find_root(source.module)
    if root then
      VxVim.walk(root, function(path, name, type)
        if (type == "file" or type == "link") and name:match("%.lua$") then
          name = path:sub(#root + 2, -5):gsub("/", ".")
          local ok, extra = pcall(M.get_extra, source, source.module .. "." .. name)
          if ok then
            extras[#extras + 1] = extra
          end
        end
      end)
    end
  end
  table.sort(extras, function(a, b)
    return a.name < b.name
  end)
  return extras
end

---@param modname string
---@param source LazyExtraSource
function M.get_extra(source, modname)
  VxVim.plugin.handle_defaults = false
  local enabled = vim.tbl_contains(M.state, modname)
  local spec = Plugin.Spec.new(nil, { optional = true, pkg = false })
  spec:parse({ import = modname })
  local imports = vim.tbl_filter(function(x)
    return x ~= modname
  end, spec.modules)
  if #imports > 0 then
    spec = Plugin.Spec.new(nil, { optional = true, pkg = false })
    spec.modules = vim.deepcopy(imports)
    spec:parse({ import = modname })
  end
  local plugins = {} ---@type string[]
  local optional = {} ---@type string[]
  for _, p in pairs(spec.plugins) do
    if p.optional then
      optional[#optional + 1] = p.name
    else
      plugins[#plugins + 1] = p.name
    end
  end
  table.sort(plugins)
  table.sort(optional)

  ---@type boolean|(fun():boolean?)|nil|WantsOpts
  local recommended = require(modname).recommended or false
  if type(recommended) == "function" then
    recommended = recommended() or false
  elseif type(recommended) == "table" then
    recommended = M.wants(recommended)
  end

  ---@type LazyExtra
  return {
    source = source,
    name = modname:sub(#source.module + 2),
    module = modname,
    enabled = enabled,
    imports = imports,
    desc = require(modname).desc,
    recommended = recommended,
    managed = vim.tbl_contains(VxVim.config.json.data.extras, modname) or not enabled,
    plugins = plugins,
    optional = optional,
  }
end
