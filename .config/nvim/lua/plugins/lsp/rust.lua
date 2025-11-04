-- Rust LSP Configuration
return {
  name = "rust",

  -- Dependencies (plugins to load)
  dependencies = {},

  -- Tools to install via Mason
  mason_tools = {},

  -- LSP servers to configure
  servers = {},

  -- Setup function for locally installed tools
  setup = function(capabilities)
    -- rust_analyzer, clippy, and rustfmt can be installed with rustup
    vim.lsp.config("rust_analyzer", {
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          diagnostics = {
            enabled = true,
          },
          check = {
            command = "clippy",
          },
        },
      },
    })
    vim.lsp.enable("rust_analyzer")
  end,
}
