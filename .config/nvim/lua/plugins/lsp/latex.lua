-- LaTeX LSP Configuration
return {
  name = "latex",

  dependencies = {},

  mason_tools = { "latexindent" },

  servers = {
    texlab = {
      settings = {
        texlab = {
          chktex = {
            onOpenAndSave = true,
            onEdit = true,
          },
          latexFormatter = "latexindent",
          latexindent = {
            modifyLineBreaks = true,
          },
        },
      },
    },
  },

  setup = function(capabilities)
    -- Setup handled by mason-lspconfig
  end,
}
