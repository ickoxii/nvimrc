-- C/C++ LSP Configuration
return {
  name = "c-cpp",

  dependencies = {},

  mason_tools = {},

  servers = {},

  setup = function(capabilities)
    require("lspconfig").clangd.setup({
      capabilities = capabilities,
    })
  end,
}
