local function create_dir(path)
  local file_state_vscode = vim.uv.fs_stat(path) or {}
  if file_state_vscode.type ~= "directory" and file_state_vscode.type ~= nil then
    vim.notify(path .. " is not directory, and is exist", vim.log.levels.WARN, { title = "template" })
    return
  end
  if file_state_vscode.type == nil then
    vim.fn.mkdir(path, "p")
    vim.notify("created: " .. path, vim.log.levels.INFO, { title = "template" })
  end
end

local templates = {
  gdb_launch = {
    name = "GDB Launch",
    type = "gdb",
    request = "launch",
    program = "main",
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
  gdb_attach = {
    name = "Attach to gdbserver :1234",
    type = "gdb",
    request = "attach",
    target = "localhost:1234",
    program = "main",
    cwd = "${workspaceFolder}",
  },
  cppdbg_launch = {
    name = "cppdbg Launch",
    type = "cppdbg",
    request = "launch",
    program = "main",
    cwd = "${workspaceFolder}",
    stopAtEntry = true,
  },
  cppdbg_gdb = {
    name = "cppdbg Attach to gdbserver :1234",
    type = "cppdbg",
    request = "launch",
    MIMode = "gdb",
    miDebuggerServerAddress = "localhost:1234",
    miDebuggerPath = "gdb",
    cwd = "${workspaceFolder}",
    program = "main",
  },
  codelldb = {
    name = "codelldb Launch",
    type = "codelldb",
    request = "launch",
    program = "main",
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
  lldb = {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = "main",
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
  pwanode = {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}",
  },
  pwanode_deno = {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    runtimeExecutable = "deno",
    runtimeArgs = {
      "run",
      "--inspect-wait",
      "--allow-all",
    },
    program = "${file}",
    cwd = "${workspaceFolder}",
    attachSimplePort = 9229,
  },
  netcoredbg = {
    type = "netcoredbg",
    name = "netcoredbg",
    request = "launch",
    program = "main",
  },
}

local task = {
  version = "2.0.0",
  tasks = {
    {
      label = "hello",
      type = "shell",
      command = "echo hello",
      group = "test",
    },
  },
}

local tmpl = {
  priority = 100,
  params = {
    json = {
      type = "string",
    },
    cwd = {
      type = "string",
    },
    file = {
      type = "string",
    },
  },
  builder = function(params)
    create_dir(params.file)
    local file_state = vim.uv.fs_stat(params.file) or {}
    if file_state.type == "file" then
      return {
        cmd = { "echo" },
        args = { "OK: " .. params.file },
        cwd = params.cwd,
      }
    end
    local json = {
      version = "0.2.0",
      configurations = {
        templates[params.json],
      },
    }
    local json_str = vim.json.encode(json)
    local pretty_json = vim.fn.system("jq .", json_str)
    local file = io.open(params.file, "w")
    if file then
      file:write(pretty_json)
      file:close()
    else
      return {
        cmd = { "echo" },
        args = { "Write Error: " .. params.file },
        cwd = params.cwd,
      }
    end
    return {
      cmd = { "echo" },
      args = { "Write: " .. params.file },
      cwd = params.cwd,
    }
  end,
}
local task_tmpl = {
  priority = 100,
  params = {
    cwd = {
      type = "string",
    },
    file = {
      type = "string",
    },
  },
  builder = function(params)
    create_dir(params.file)
    local file_state = vim.uv.fs_stat(params.file) or {}
    if file_state.type == "file" then
      return {
        cmd = { "echo" },
        args = { "OK: " .. params.file },
        cwd = params.cwd,
      }
    end
    local json_str = vim.json.encode(task)
    local pretty_json = vim.fn.system("jq .", json_str)
    local file = io.open(params.file, "w")
    if file then
      file:write(pretty_json)
      file:close()
    else
      return {
        cmd = { "echo" },
        args = { "Write Error: " .. params.file },
        cwd = params.cwd,
      }
    end
    return {
      cmd = { "echo" },
      args = { "Write: " .. params.file },
      cwd = params.cwd,
    }
  end,
}

local provider = {
  name = "template",
  generator = function(_, cb)
    local root = VxUtil.root()
    local vscode = root .. "/.vscode"
    local overseer = require("overseer")
    local ret = {}
    for name, _ in pairs(templates) do
      table.insert(
        ret,
        overseer.wrap_template(
          tmpl,
          { name = string.format("%s %s", "template", name) },
          { json = name, cwd = VxUtil.root(), file = vscode .. "/launch.json" }
        )
      )
    end
    table.insert(
      ret,
      overseer.wrap_template(
        task_tmpl,
        { name = "template task" },
        { cwd = VxUtil.root(), file = vscode .. "/tasks.json" }
      )
    )
    cb(ret)
  end,
}

return {
  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },

  -- library used by other plugins
  { "nvim-lua/plenary.nvim", lazy = true },

  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerSaveBundle",
      "OverseerLoadBundle",
      "OverseerDeleteBundle",
      "OverseerRunCmd",
      "OverseerRun",
      "OverseerInfo",
      "OverseerBuild",
      "OverseerQuickAction",
      "OverseerTaskAction",
      "OverseerClearCache",
    },
    opts = {
      dap = false,
      task_list = {
        bindings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
      form = {
        win_opts = {
          winblend = 0,
        },
      },
      confirm = {
        win_opts = {
          winblend = 0,
        },
      },
      task_win = {
        win_opts = {
          winblend = 0,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>ow", "<cmd>OverseerToggle<cr>",      desc = "Task list" },
      { "<leader>oo", "<cmd>OverseerRun<cr>",         desc = "Run task" },
      { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Action recent task" },
      { "<leader>oi", "<cmd>OverseerInfo<cr>",        desc = "Overseer Info" },
      { "<leader>ob", "<cmd>OverseerBuild<cr>",       desc = "Task builder" },
      { "<leader>ot", "<cmd>OverseerTaskAction<cr>",  desc = "Task action" },
      { "<leader>oc", "<cmd>OverseerClearCache<cr>",  desc = "Clear cache" },
    },
    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)
      overseer.register_template(provider)
    end,
  },
}
