local options = {
  ensure_installed = {
    "html",
    "cssls",
    "ts_ls",
    "eslint",
    "pyright",
    "rust_analyzer",
    "clangd"
  },
  automatic_enable = {
    exclude = {
      "jdtls"
    },
  },
}

return options;
