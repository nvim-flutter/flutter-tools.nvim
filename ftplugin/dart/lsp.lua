if vim.b.did_ftplugin_dart_lsp then
  return
end
vim.b.did_ftplugin_dart_lsp = true
require('flutter-tools.lsp').attach()
