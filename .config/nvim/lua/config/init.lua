require("config.remaps")
require("config.set")
require("config.lazy")
require("config.tex")
require("config.dot")

--
-- spell check on markdown files
--
vim.api.nvim_create_augroup("spellcheck", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "tex" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "en_us" }
    vim.keymap.set("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { buffer = true })
  end,
  group = "spellcheck",
})

--
-- Vim DOCX (vdocx) augroup
--
vim.filetype.add({
  extension = {
    vdocx = "vdocx",
  },
})

-- Create an autocommand group for vdocx settings
vim.api.nvim_create_augroup("VDocxSettings", { clear = true })

-- Load specific settings for vdocx files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vdocx",
  callback = function()
    require("config.vdocx")
  end,
  group = "VDocxSettings",
})

--
-- remember fold groups
--
vim.api.nvim_create_augroup("remember_folds", { clear = true })

-- save folds on exit
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = "remember_folds",
  callback = function()
    if vim.fn.expand("%") ~= "" then -- Check if the buffer has a file name
      vim.cmd("mkview")
    end
  end,
})

-- load folds on enter
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = "remember_folds",
  callback = function()
    if vim.fn.expand("%") ~= "" then -- Check if the buffer has a file name
      vim.cmd("silent! loadview")
    end
  end,
})
