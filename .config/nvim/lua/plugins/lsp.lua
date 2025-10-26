-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

-- `:help lspconfig-all` to view all supported lsp's

-- `:LspInstall latex` lol

-- Modular LSP Configuration
-- Load only the language servers you need based on NVIM_LSP_LANGS environment variable
-- Example: export NVIM_LSP_LANGS="rust,lua"

return {
  -- `lazydev` configures Lua LSP for your Neovim config
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Java support (only loads if java is in NVIM_LSP_LANGS)
  {
    "nvim-java/nvim-java",
    opts = {},
    cond = function()
      local env_langs = os.getenv('NVIM_LSP_LANGS')
      if not env_langs then
        -- Not in container, load by default
        if not (os.getenv('container') or os.getenv('DOCKER_CONTAINER')) then
          return true
        end
        return false
      end
      -- Check if java is in the list
      for lang in env_langs:gmatch('[^,]+') do
        if lang:match("^%s*(.-)%s*$") == 'java' then
          return true
        end
      end
      return false
    end,
  },

  -- Main lsp config
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "hrsh7th/cmp-nvim-lsp",
    },

    config = function()
      -- Load the LSP loader
      local lsp_loader = require('config.lsp-loader')

      -- Load language-specific configs
      local lang_configs = {}
      local lsp_dir = vim.fn.stdpath('config') .. '/lua/plugins/lsp'

      -- Check if lsp directory exists
      if vim.fn.isdirectory(lsp_dir) == 1 then
        for _, file in ipairs(vim.fn.readdir(lsp_dir)) do
          if file:match('%.lua$') then
            local module_name = file:gsub('%.lua$', '')
            local ok, config = pcall(require, 'plugins.lsp.' .. module_name)
            if ok and config and config.name then
              lang_configs[config.name] = config
            else
              if not ok then
                vim.notify('Failed to load LSP config: ' .. module_name .. '\nError: ' .. tostring(config), vim.log.levels.WARN)
              end
            end
          end
        end
      end

      -- Collect servers and tools to install based on enabled languages
      local servers = {}
      local ensure_installed = {}

      if lsp_loader.load_all then
        -- Load everything
        for _, config in pairs(lang_configs) do
          for server, opts in pairs(config.servers or {}) do
            servers[server] = opts
          end
          for _, tool in ipairs(config.mason_tools or {}) do
            table.insert(ensure_installed, tool)
          end
        end
      else
        -- Load only enabled languages
        for _, lang in ipairs(lsp_loader.enabled_languages) do
          local config = lang_configs[lang]
          if config then
            for server, opts in pairs(config.servers or {}) do
              servers[server] = opts
            end
            for _, tool in ipairs(config.mason_tools or {}) do
              table.insert(ensure_installed, tool)
            end
          end
        end
      end

      -- LSP Attach autocmd
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map("gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Search [D]ocument [S]ymbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Search [W]orkspace [S]ymbols")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0, desc = "LSP: View man page" })
          vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, { buffer = 0, desc = "LSP: Goto [D]iagnostic [N]ext" })
          vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, { buffer = 0, desc = "LSP: Goto [D]iagnostic [P]rev" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = 0, desc = "LSP: [R]e[n]ame" })

          local function client_supports_method(client, method, bufnr)
            if vim.fn.has("nvim-0.11") == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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

          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "[T]oggle Inlay [H]ints")
          end
        end,
      })

      vim.diagnostic.config({
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
      local cmp_lsp = require("cmp_nvim_lsp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities()
      )

      -- Setup mason-tool-installer
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      -- Setup mason-lspconfig
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
        },
      })

      -- Setup locally installed LSPs
      for _, config in pairs(lang_configs) do
        if (lsp_loader.load_all or lsp_loader.should_load(config.name)) and config.setup then
          config.setup(capabilities)
        end
      end
    end,
  },

  -- conform for formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = "n",
        desc = "Conform: [C]onform [F]ormat buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        tex = { "latexindent" },
        rust = { "rustfmt" },
        ["*"] = { "trim_whitespace", "trim_newlines" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        local disable_filetypes = { json = true, c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = "never"
        else
          lsp_format_opt = "fallback"
        end
        return {
          timeout_ms = 5000,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
      },
    },
    init = function()
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
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
      },
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
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
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete({}),
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
        }),
        sources = {
          { name = "lazydev", group_index = 0 },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "nvim_lsp_signature_help" },
        },
      })
    end,
  },
}
