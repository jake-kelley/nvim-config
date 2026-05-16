-- Optional: ad-hoc floating terminal on <C-\> for one-off commands.
return {
  "akinsho/toggleterm.nvim",
  keys = { { [[<c-\>]], desc = "Toggle floating terminal" } },
  opts = {
    open_mapping = [[<c-\>]],
    direction = "float",
    float_opts = { border = "rounded" },
    start_in_insert = true,
  },
}
