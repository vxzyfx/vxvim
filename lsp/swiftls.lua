---@brief
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- Language server for Swift and C/C++/Objective-C.

local M = {}

function M.tbl_flatten(t)
  --- @diagnostic disable-next-line:deprecated
  return vim.iter(t):flatten(math.huge):totable()
end

function M.strip_archive_subpath(path)
  -- Matches regex from zip.vim / tar.vim
  path = vim.fn.substitute(path, 'zipfile://\\(.\\{-}\\)::[^\\\\].*$', '\\1', '')
  path = vim.fn.substitute(path, 'tarfile:\\(.\\{-}\\)::.*$', '\\1', '')
  return path
end

local function escape_wildcards(path)
  return path:gsub('([%[%]%?%*])', '\\%1')
end

function M.search_ancestors(startpath, func)
  vim.validate('func', func, 'function')
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in vim.fs.parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

function M.root_pattern(...)
  local patterns = M.tbl_flatten { ... }
  return function(startpath)
    startpath = M.strip_archive_subpath(startpath)
    for _, pattern in ipairs(patterns) do
      local match = M.search_ancestors(startpath, function(path)
        for _, p in ipairs(vim.fn.glob(table.concat({ escape_wildcards(path), pattern }, '/'), true, true)) do
          if vim.uv.fs_stat(p) then
            return path
          end
        end
      end)

      if match ~= nil then
        return match
      end
    end
  end
end

return {
  cmd = { 'sourcekit-lsp' },
  filetypes = { 'swift', 'objc', 'objcpp' },
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    on_dir(
      M.root_pattern 'buildServer.json' (filename)
      or M.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      -- better to keep it at the end, because some modularized apps contain multiple Package.swift files
      or M.root_pattern('compile_commands.json', 'Package.swift')(filename)
      or vim.fs.dirname(vim.fs.find('.git', { path = filename, upward = true })[1])
    )
  end,
  get_language_id = function(_, ftype)
    local t = { objc = 'objective-c', objcpp = 'objective-cpp' }
    return t[ftype] or ftype
  end,
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
  capabilities = vim.tbl_deep_extend("force", vim.deepcopy(VxUtil.lsp.capabilities), {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
    textDocument = {
      diagnostic = {
        dynamicRegistration = true,
        relatedDocumentSupport = true,
      },
    },
  }),
}
