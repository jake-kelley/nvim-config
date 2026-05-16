return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    file_types = { "markdown" },
    heading = {
      icons = { "Tasks  ", "List  ", "Group  ", "Item  " },
    },
    checkbox = {
      unchecked = { icon = "[ ] " },
      checked   = { icon = "[x] " },
    },
  },
}
