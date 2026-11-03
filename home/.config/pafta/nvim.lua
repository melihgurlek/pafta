-- Pafta rice: one colourscheme, paper by day, chart by night. Kigae links
-- ~/.config/nvim/lua/plugins/kigae.lua here. The `background` option picks the side
-- (LazyVim/Neovim follow the terminal's light/dark report), and colors/pafta.lua redraws on change.
vim.api.nvim_create_autocmd("OptionSet", {
  group = vim.api.nvim_create_augroup("pafta_background", { clear = true }),
  pattern = "background",
  desc = "Re-apply Pafta when the background flips between paper and night",
  callback = function()
    if vim.g.colors_name == "pafta" then
      vim.schedule(function()
        vim.cmd.colorscheme("pafta")
      end)
    end
  end,
})

return {
  { dir = vim.fn.expand("~/.config/pafta/nvim"), name = "pafta", lazy = false, priority = 1000 },
  { "LazyVim/LazyVim", opts = { colorscheme = "pafta" } },
}
