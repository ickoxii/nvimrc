-- LSP Configuration Loader
-- Loads language servers based on NVIM_LSP_LANGS environment variable
-- Set via: export NVIM_LSP_LANGS="rust,lua"

local function get_enabled_languages()
  local enabled = {}

  -- Check environment variable
  local env_langs = os.getenv("NVIM_LSP_LANGS")
  if env_langs then
    for lang in env_langs:gmatch("[^,]+") do
      table.insert(enabled, lang:match("^%s*(.-)%s*$"))
    end
    return enabled
  end

  -- Default: load all if not in a container
  if os.getenv("container") or os.getenv("DOCKER_CONTAINER") then
    return {} -- load nothing by default in containers
  end

  return { "all" } -- load everything
end

local enabled_langs = get_enabled_languages()
local load_all = vim.tbl_contains(enabled_langs, "all")

-- Helper function to check if a language should be loaded
local function should_load(lang)
  return load_all or vim.tbl_contains(enabled_langs, lang)
end

return {
  enabled_languages = enabled_langs,
  should_load = should_load,
  load_all = load_all,
}
