-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

-- `:help lspconfig-all` to view all supported lsp's

-- `:LspInstall latex` lol

return {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Main lsp config
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- general lsp management
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      { "j-hui/fidget.nvim", opts = {} },

      -- java lsp with springboot support
      { "nvim-java/nvim-java", opts = {} },

      -- autocompletion
      "hrsh7th/cmp-nvim-lsp",
    },

    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          -- helper function to easily define mappings
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          --
          -- Keymaps
          --
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map("gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
          map(
            "<leader>ds",
            require("telescope.builtin").lsp_document_symbols,
            "Search [D]ocument [S]ymbols (variables, functions, types, etc.)"
          )
          map(
            "<leader>ws",
            require("telescope.builtin").lsp_dynamic_workspace_symbols,
            "Search [W]orkspace [S]ymbols (variables, functions, types, etc.)"
          )

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0, desc = "LSP: View man page" })
          vim.keymap.set(
            "n",
            "<leader>dn",
            vim.diagnostic.goto_next,
            { buffer = 0, desc = "LSP: Goto [D]iagnostic [N]ext" }
          )
          vim.keymap.set(
            "n",
            "<leader>dp",
            vim.diagnostic.goto_prev,
            { buffer = 0, desc = "LSP: Goto [D]iagnostic [P]rev" }
          )
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = 0, desc = "LSP: [R]e[n]ame" })
          -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer some lsp support methods only in specific files
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has("nvim-0.11") == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if
            client
            and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
          then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "[T]oggle Inlay [H]ints")
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config({
        -- update_in_insert = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "",
          source = "",
          header = "",
          prefix = "",
        },
      })

      -- Define Capabilities
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_lsp = require("cmp_nvim_lsp")
      local capabilities =
        vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), cmp_lsp.default_capabilities())

      -- Define language servers to be managed by Mason
      local servers = {
        -- If you want to use tools already installed on your machine, do
        -- not list it here, but do call its setup function later.
        -- clangd = {},
        -- gopls = {},
        -- rust_analyzer = {},

        -- Emmet language server for React projects
        -- https://github.com/olrtg/emmet-language-server
        -- `npm install -g @olrtg/emmet-language-server`
        emmet_language_server = {},

        pyright = {},

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = capabilities,
          settings = {
            Lua = {
              runtime = { version = "Lua 5.1" },
              diagnostics = {
                -- globals = { "vim", "it", "describe", "before_each", "after_each" },
                disable = { "missing-fields" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },

        -- marksman = {
        --   cmd = { "marksman", "server"},
        --   filetypes = { "markdown", "markdown.mdx" },
        --   single_file_support = true,
        -- },
        -- mdformat = {},
        -- marksman = {},

        -- https://github.com/latex-lsp/texlab/wiki/Configuration
        -- :lua =require('lspconfig').texlab
        texlab = {
          settings = {
            texlab = {
              chktex = {
                onOpenAndSave = true,
                onEdit = true,
              },
              -- formatterLineLength = 80
              -- https://github.com/cmhughes/latexindent.pl
              latexFormatter = "latexindent",
              latexindent = {
                modifyLineBreaks = true,
              },
            },
          },
        },
      }

      --
      -- Define other tools to be managed by Mason
      --
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- 'tex-fmt',
        "latexindent", -- https://github.com/cmhughes/latexindent.pl
        -- "mdformat",
        -- "marksman",
        "stylua", -- Used to format Lua code
      })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      ---@diagnostic disable-next-line: missing-fields
      require("mason-lspconfig").setup({
        ensure_installed = {}, -- explicitly set to empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
        },
      })

      --
      -- setup individual lsp's
      -- this is where you can setup locally installed lsp's and tools
      --
      -- require('java').setup({}) -- setup `java` before `jdtls`
      require("lspconfig").jdtls.setup({})
      require("lspconfig").clangd.setup({})
      require("lspconfig").pyright.setup({})

      -- rust_analyzer, clippy, and rustfmt can be installed with rustup
      -- (they automatically downloaded for me after a `rustup update`)
      require("lspconfig").rust_analyzer.setup({
        settings = {
          ["rust-analyzer"] = {
            diagnostics = {
              enabled = true,
            },
            check = {
              command = "clippy", -- use clippy for linting
            },
            -- rustfmt = {
            --   enable = true, -- use rustfmt for formatting
            -- }
          },
        },
      })
    end,
  },

  -- conform and editorconfig for formatting
  {
    "stevearc/conform.nvim",

    event = { "BufWritePre" },
    cmd = { "ConformInfo" },

    -- dependencies = {
    --   "gpanders/editorconfig.nvim"
    -- },

    keys = {
      {
        -- Customize or remove this keymap to your liking
        "<leader>cf",
        function()
          -- require("conform").format({ async = true })
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = "n",
        desc = "Conform: [C]onform [F]ormat buffer",
      },
    },

    -- This will provide type hinting with LuaLS
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      -- Define your formatters
      formatters_by_ft = {
        lua = { "stylua" },
        -- markdown = { "mdformat" },
        -- markdown = { "marksman" },
        tex = { "latexindent" },
        rust = { "rustfmt" },
        ["*"] = { "trim_whitespace", "trim_newlines" },
      },

      -- Set default options
      default_format_opts = {
        lsp_format = "fallback",
      },

      -- Set up format-on-save
      -- format_on_save = { timeout_ms = 500 },
      format_on_save = function(bufnr)
        local disable_filetypes = { json = true, c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = "never"
        else
          lsp_format_opt = "fallback"
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,

      -- Customize formatters
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
        latexindent = {
          prepend_args = { "-m" },
        },
      },
    },

    init = function()
      -- If you want the formatexpr, here is the place to set it
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },

  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
      -- See `:help cmp`
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      luasnip.config.setup({})

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        completion = { completeopt = "menu,menuone,noinsert" },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          -- Manually trigger a completion from nvim-cmp.
          ["<C-Space>"] = cmp.mapping.complete({}),

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ["<C-l>"] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { "i", "s" }),
          ["<C-h>"] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { "i", "s" }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        }),
        sources = {
          {
            name = "lazydev",
            -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
            group_index = 0,
          },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "nvim_lsp_signature_help" },
          -- { name = 'buffer' },
        },
      })
    end,
  },
}
