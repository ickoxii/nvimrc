-- Java LSP Configuration
-- Note: nvim-java plugin is loaded separately in lua/plugins/lsp.lua
return {
  name = 'java',

  -- No dependencies here - nvim-java is conditionally loaded in main lsp.lua
  dependencies = {
    "nvim-java/nvim-java",
  },

  mason_tools = {},

  servers = {},

  setup = function(capabilities)
    -- Requires nvim-java plugin to be loaded
    vim.lsp.config('jdtls', {
      capabilities = capabilities
    })
    vim.lsp.enable({'jdtls'})
  end,
}
