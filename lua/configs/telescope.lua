local options = {
  defaults = {},
  pickers = {
    find_files = {
      hidden = true,
      no_ignore = true,
    },
    live_grep = {
      additional_args = function ()
        return { "--no-ignore" }
      end,
    },
  },
}

return options
