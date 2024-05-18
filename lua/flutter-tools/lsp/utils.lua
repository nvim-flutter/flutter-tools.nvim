local M = {}

local lsp = vim.lsp

M.SERVER_NAME = "dartls"

-- TODO: Remove after compatibility with Neovim=0.9 is dropped
local get_clients = vim.fn.has("nvim-0.10") == 1 and lsp.get_clients or lsp.get_active_clients

---@param bufnr number?
---@return vim.lsp.Client?
function M.get_dartls_client(bufnr) return get_clients({ name = M.SERVER_NAME, bufnr = bufnr })[1] end

return M
