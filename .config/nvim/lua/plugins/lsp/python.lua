-- Python LSP Configuration
return {
  name = "python",

  dependencies = {},

  mason_tools = {},

  servers = {
    pyright = {},
  },

  setup = function(capabilities)
    require("lspconfig").pyright.setup({
      capabilities = capabilities,
    })
  end,
}
