local M = {}

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd(string.format([[echomsg "%s"]], msg))
end

function M.autocommands_create(definitions)
  for group_name, definition in pairs(definitions) do
    vim.cmd("augroup " .. group_name)
    vim.cmd("autocmd!")
    for _, def in pairs(definition) do
      local command = table.concat(vim.tbl_flatten {"autocmd", def}, " ")
      vim.cmd(command)
    end
    vim.cmd("augroup END")
  end
end

---@param name string
---@return string
function M.display_name(name)
  return " • " .. name .. " "
end

return M
