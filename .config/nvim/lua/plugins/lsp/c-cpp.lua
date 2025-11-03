-- C/C++ LSP Configuration
return {
  name = "c-cpp",

  dependencies = {},

  mason_tools = {},

  servers = {},

  setup = function(capabilities)
    vim.lsp.config('clangd', {
      capabilities = capabilities
    })
    vim.lsp.enable({'clangd'})
  end,
}
