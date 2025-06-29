-- See section 'DISABLING' in :h ftplugin
if vim.b.flutter_tools_did_ftplugin then return end
vim.b.flutter_tools_did_ftplugin = 1

require("flutter-tools.lsp").attach()
local path = require("flutter-tools.utils.path")

vim.opt_local.comments = [[sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,:///,://]]
vim.opt_local.commentstring = [[//%s]]
vim.opt.includeexpr = "v:lua.require('flutter-tools.resolve_url').resolve_url(v:fname)"

local full_path = vim.fn.expand("%:p")
-- Prevent writes to files in the pub cache and FVM folder.
if path.is_flutter_dependency_path(full_path) then vim.opt_local.modifiable = false end
