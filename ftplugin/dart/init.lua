require("flutter-tools.lsp").attach()

vim.api.nvim_buf_set_option(0, "comments", [[sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,:///,://]])
vim.api.nvim_buf_set_option(0, "commentstring", [[//%s]])
