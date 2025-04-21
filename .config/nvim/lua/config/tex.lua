-- augroups for working with latex

local pdftex = vim.api.nvim_create_augroup("pdftex", { clear = true })

-- use line wrapping
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.tex" },
  group = pdftex,
  callback = function()
    -- vim.opt_local.textwidth = 120 -- 120 char width
    vim.opt_local.wrap = false -- wrap at end of line
    vim.opt_local.linebreak = true -- break line without splitting words
    vim.opt_local.breakindent = true -- indent line break
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
