return {
  -- LSP for Cargo.toml
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    keys = {
      { "<leader>ct", function() require("crates").toggle() end,                  ft = "toml", desc = "Crates Toggle" },
      { "<leader>cv", function() require("crates").show_versions_popup() end,     ft = "toml", desc = "Crates Versions" },
      { "<leader>cf", function() require("crates").show_features_popup() end,     ft = "toml", desc = "Crates Features" },
      { "<leader>cd", function() require("crates").show_dependencies_popup() end, ft = "toml", desc = "Crates Dependencies" },
    },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },


  {
    "mrcjkb/rustaceanvim",
    version = '^6',
    ft = { "rust" },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>cR", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Action", buffer = bufnr })
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Add clippy lints for Rust if using rust-analyzer
            checkOnSave = true,
            -- Enable diagnostics if using rust-analyzer
            diagnostics = {
              enable = true,
            },
            procMacro = {
              enable = true,
              ignored = {},
            },
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      local codelldb = vim.g.vx_codelldb
      local library_path = vim.g.vx_liblldb
      opts.dap = {
        adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
      }
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable("rust-analyzer") == 0 then
        VxUtil.error(
          "**rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
          { title = "rustaceanvim" }
        )
      end
    end,
  },

}
