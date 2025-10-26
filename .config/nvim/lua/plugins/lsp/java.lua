-- Java LSP Configuration
-- Note: nvim-java plugin is loaded separately in lua/plugins/lsp.lua
return {
  name = 'java',

  -- No dependencies here - nvim-java is conditionally loaded in main lsp.lua
  dependencies = {},

  mason_tools = {},

  servers = {},

  setup = function(capabilities)
    -- Requires nvim-java plugin to be loaded
    require("lspconfig").jdtls.setup({
      capabilities = capabilities,
    })
  end,
}
