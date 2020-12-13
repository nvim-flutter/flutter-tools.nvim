local M = {}

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd(string.format([[echomsg "%s"]], msg))
end

return M
