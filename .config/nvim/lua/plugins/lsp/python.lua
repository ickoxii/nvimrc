-- Python LSP Configuration
return {
  name = "python",

  dependencies = {},

  mason_tools = {},

  servers = {
    pyright = {},
  },

  setup = function(capabilities)
    vim.lsp.config("pyright", {
      capabilities = capabilities,
    })
    vim.lsp.config("ruff", {
      capabilities = capabilities,
    })
    vim.lsp.enable({ "pyright", "ruff" })
  end,
}
