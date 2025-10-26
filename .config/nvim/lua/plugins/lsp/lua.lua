-- Lua LSP Configuration
return {
  name = "lua",

  dependencies = {},

  mason_tools = { "stylua" },

  servers = {
    lua_ls = {
      settings = {
        Lua = {
          runtime = { version = "Lua 5.1" },
          diagnostics = {
            disable = { "missing-fields" },
          },
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    },
  },

  setup = function(capabilities)
    -- Setup handled by mason-lspconfig
  end,
}
