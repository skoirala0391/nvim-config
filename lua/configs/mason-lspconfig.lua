local options = {
  ensure_installed = {
    "html",
    "cssls",
    "ts_ls",
    "eslint",
    "pyright"
  },
  automatic_enable = {
    exclude = {
      "jdtls"
    },
  },
}

return options;
