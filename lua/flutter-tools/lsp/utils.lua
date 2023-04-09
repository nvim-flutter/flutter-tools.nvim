local M = {}

local lsp = vim.lsp

M.SERVER_NAME = "dartls"

---@param bufnr number?
---@return lsp.Client?
function M.get_dartls_client(bufnr)
  return lsp.get_active_clients({ name = M.SERVER_NAME, bufnr = bufnr })[1]
end

return M
