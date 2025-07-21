-- augroups for working with latex

local pdftex = vim.api.nvim_create_augroup("pdftex", { clear = true })

-- use line wrapping
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.tex" },
  group = pdftex,
  callback = function()
    -- vim.opt_local.textwidth = 80 -- 120 char width
    -- vim.opt_local.wrap = false -- enable visual wrapping
    -- vim.opt_local.linebreak = true -- break line without splitting words
    -- vim.opt_local.breakindent = true -- indent line break
    -- vim.opt_local.formatoptions = "tcqja" -- auto-wrap text and comments, gq formats, remove comment leader when joining

    -- Set colored column at textwidth
    -- vim.opt_local.colorcolumn = "80"

    -- Improve navigation in wrapped lines
    -- vim.keymap.set("n", "j", "gj", { buffer = true, silent = true })
    -- vim.keymap.set("n", "k", "gk", { buffer = true, silent = true })
  end,
})

-- Toggle visual wrapping with <leader>tw
vim.api.nvim_create_user_command("ToggleWrap", function()
  vim.opt_local.wrap = not vim.opt_local.wrap
  print("Wrap: " .. (vim.opt_local.wrap:get() and "ON" or "OFF"))
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.keymap.set("n", "<leader>tw", ":ToggleWrap<CR>", { buffer = true, silent = true, desc = "Toggle wrap" })
  end,
})

-- compile file on save
vim.g.latex_engine = "tectonic"

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.tex", "*.bib" },
  group = pdftex,
  callback = function()
    -- print(vim.g.latex_engine .. " " .. vim.fn.expand("%:p"))
    local engine = vim.g.latex_engine or "tectonic"
    os.execute(engine .. " " .. vim.fn.expand("%:p") .. " &> /dev/null &")
  end,
})

vim.api.nvim_create_user_command("ToggleTexEngine", function()
  if vim.g.latex_engine == "tectonic" then
    vim.g.latex_engine = "xelatex"
  else
    vim.g.latex_engine = "tectonic"
  end
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.keymap.set(
      "n",
      "<leader>te",
      ":ToggleTexEngine<CR>",
      { buffer = true, silent = true, desc = "Toggle TeX engine" }
    )
  end,
})
