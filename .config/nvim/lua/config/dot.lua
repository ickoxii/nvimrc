-- Auto-compile .dot files to PDF on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.dot",
  callback = function(args)
    local filepath = args.file
    local pdfpath = filepath:gsub("%.dot$", ".pdf")
    vim.fn.jobstart({ "dot", "-Tpdf", filepath, "-o", pdfpath }, {
      on_exit = function(_, code, _)
        if code ~= 0 then
          vim.notify("Error compiling " .. filepath, vim.log.levels.ERROR)
        end
      end,
    })
  end,
})
