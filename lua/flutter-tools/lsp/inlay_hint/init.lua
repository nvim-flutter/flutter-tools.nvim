local M = {}
function M.request()
  local params = vim.lsp.util.make_range_params()

  local clients = vim.lsp.get_active_clients({ name = "dartls" })
  for _, client in ipairs(clients) do
    client.request("textDocument/inlayHint", params, nil, 0);
  end
end

M.on_inlay_hint = require "flutter-tools.lsp.inlay_hint.utils".on_inlay_hint

return M
