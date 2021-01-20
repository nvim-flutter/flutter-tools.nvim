local utils = require "flutter-tools/utils"
local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"

local M = {
  initialised = false
}

function M.setup(config)
  config = config or {}
  if M.initialised then
    return utils.echomsg [[DartLS has already been setup!]]
  end
  local success, lspconfig = pcall(require, "lspconfig")
  if not success or not lspconfig then
    utils.echomsg("You must have the neovim/nvim-lspconfig module installed", "Error")
    return
  end

  local cfg = {
    flags = {allow_incremental_sync = true},
    init_options = {
      closingLabels = true,
      outline = true,
      flutterOutline = true
    },
    handlers = {
      ["dart/textDocument/publishClosingLabels"] = labels.closing_tags,
      ["dart/textDocument/publishOutline"] = outline.document_outline
    }
  }

  config = vim.tbl_deep_extend("force", cfg, config)
  lspconfig.dartls.setup(config)
  M.initialised = true
end

return M
