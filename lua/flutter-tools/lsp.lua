local utils = require "flutter-tools/utils"
local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"

local M = {}

function M.setup(config)
  local success, lspconfig = pcall(require, "lspconfig")
  if not success or not lspconfig then
    utils.echomsg("You must have the neovim/nvim-lspconfig module installed", "Error")
    return
  end

  local options = config.options or {}
  local cfg = {
    flags = {allow_incremental_sync = true},
    init_options = {
      closingLabels = true,
      outline = true,
      flutterOutline = true
    },
    handlers = {
      ["dart/textDocument/publishClosingLabels"] = labels.closing_tags(options.closing_tags),
      ["dart/textDocument/publishOutline"] = outline.document_outline(options.outline)
    }
  }

  cfg.options = nil

  config = vim.tbl_deep_extend("force", cfg, config)
  lspconfig.dartls.setup(config)
end

return M
