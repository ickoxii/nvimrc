--  Color Scheme Manager
--  Helps manage different color schemes.

-- applies a background
function Paint(color)
  color = color or "rose-pine-moon"
  vim.cmd.colorscheme(color)

  vim.api.nvim_set_hl(0, "Normal", { bg = "none" }) -- background, normal window
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" }) -- background, floating window
end

return {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    require("rose-pine").setup({
      disable_background = true,
      styles = {
        bold = false,
        italic = false,
        transparency = true,
      },
    })

    Paint()
  end,
}
