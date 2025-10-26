-- Parser generator tool and incremental parsing library. Builds a concrete
-- syntax tree that is updated while the file is edited
--
-- https://github.com/nvim-treesitter/nvim-treesitter
-- https://github.com/tree-sitter/tree-sitter

-- Modular Treesitter: only install what you ask for via NVIM_TS_LANGS (or NVIM_LSP_LANGS)

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  main = "nvim-treesitter.configs",
  opts = (function()
    -- helpers --
    local function split_csv(s)
      if not s or s == "" then
        return {}
      end
      local t = {}
      for part in s:gmatch("[^,]+") do
        -- trim spaces
        part = part:match("^%s*(.-)%s*$")
        if part ~= "" then
          table.insert(t, part)
        end
      end
      return t
    end

    local function push(tbl, val, seen)
      if not seen[val] then
        table.insert(tbl, val)
        seen[val] = true
      end
    end

    local function in_container()
      return (os.getenv("container") or os.getenv("DOCKER_CONTAINER")) and true or false
    end

    -- Map “language intents” -> actual parser names
    local expand = {
      -- basics
      lua = { "lua", "luadoc" },
      vim = { "vim", "vimdoc", "query" },
      bash = { "bash" },
      c = { "c" },
      cpp = { "cpp" },
      html = { "html" },
      css = { "css" },
      java = { "java" },
      rust = { "rust" },
      go = { "go" },
      latex = { "latex" },
      typescript = { "typescript" },
      javascript = { "javascript", "jsdoc" },
      markdown = { "markdown", "markdown_inline" },
      python = { "python" },
      yaml = { "yaml" },
      json = { "json" },
    }

    -- Collect desired langs:
    -- Prefer NVIM_TS_LANGS; if unset, fall back to NVIM_LSP_LANGS
    local env = os.getenv("NVIM_TS_LANGS") or os.getenv("NVIM_LSP_LANGS") or ""
    local requested = split_csv(env)

    -- Always keep a tiny core so your config stays highlighted
    local ensure, seen = {}, {}
    for _, core in ipairs({ "lua", "vim" }) do
      for _, p in ipairs(expand[core]) do
        push(ensure, p, seen)
      end
    end

    -- Expand user requests
    for _, lang in ipairs(requested) do
      local pack = expand[lang]
      if pack then
        for _, p in ipairs(pack) do
          push(ensure, p, seen)
        end
      else
        -- If user provided an exact parser name, accept it as-is
        push(ensure, lang, seen)
      end
    end

    -- If nothing was requested and we’re NOT in a container, provide a sane small default
    if #requested == 0 and not in_container() then
      for _, p in ipairs({
        "bash",
        "c",
        "cpp",
        "diff",
        "go",
        "html",
        "java",
        "javascript",
        "jsdoc",
        "latex",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "query",
        "rust",
        "typescript",
        "vim",
        "vimdoc",
      }) do
        push(ensure, p, seen)
      end
    end

    -- Auto-install can try to compile grammars; turn it off in containers
    local auto_install = not in_container()

    return {
      ensure_installed = ensure,
      sync_install = false,
      auto_install = auto_install,

      indent = {
        enable = true,
      },

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },
    }
  end)(),
}
