require("flutter-tools.lsp").attach()

vim.opt_local.comments = [[sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,:///,://]]
vim.opt_local.commentstring = [[//%s]]

local full_path = vim.fn.expand("%:p")
-- Prevent writes to files in the pub cache and FVM folder.
if
     string.find(full_path, ".pub-cache")
  or string.find(full_path, [[Pub\Cache]])
  or string.find(full_path, "/fvm/versions/")
then
  vim.opt_local.modifiable = false
end
