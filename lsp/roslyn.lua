---@brief
---
--- https://github.com/seblyng/roslyn.nvim
---
return {
  name = "roslyn",
  offset_encoding = "utf-8",
  cmd = {
    "Microsoft.CodeAnalysis.LanguageServer",
    "--logLevel=Information",
    "--extensionLogDirectory=" .. vim.fs.joinpath(vim.fs.dirname(vim.lsp.get_log_path()), "roslyn"),
    "--stdio",
  },
  filetypes = { "cs" },
  on_attach = function(client, buffer)
    VxUtil.lsp.on_attach(client, buffer)
  end,
  capabilities = {
    -- HACK: Doesn't show any diagnostics if we do not set this to true
    textDocument = {
      diagnostic = {
        dynamicRegistration = true,
      },
    },
  },
  settings = {
    ["csharp|background_analysis"] = {
      dotnet_analyzer_diagnostics_scope = "fullSolution",
      dotnet_compiler_diagnostics_scope = "fullSolution",
    },
    ["csharp|inlay_hints"] = {
      csharp_enable_inlay_hints_for_implicit_object_creation = true,
      csharp_enable_inlay_hints_for_implicit_variable_types = true,
      csharp_enable_inlay_hints_for_lambda_parameter_types = true,
      csharp_enable_inlay_hints_for_types = true,
      dotnet_enable_inlay_hints_for_indexer_parameters = true,
      dotnet_enable_inlay_hints_for_literal_parameters = true,
      dotnet_enable_inlay_hints_for_object_creation_parameters = true,
      dotnet_enable_inlay_hints_for_other_parameters = true,
      dotnet_enable_inlay_hints_for_parameters = true,
      dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
    },
    ["csharp|symbol_search"] = {
      dotnet_search_reference_assemblies = true,
    },
    ["csharp|completion"] = {
      dotnet_show_name_completion_suggestions = true,
      dotnet_show_completion_items_from_unimported_namespaces = true,
      dotnet_provide_regex_completions = true,
    },
    ["csharp|code_lens"] = {
      dotnet_enable_references_code_lens = true,
    },
  },
}
