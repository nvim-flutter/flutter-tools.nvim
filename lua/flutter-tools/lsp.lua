local utils = require "flutter-tools/utils"
local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"

local fn = vim.fn

local M = {
  initialised = false
}

local function analysis_server_snapshot_path(dart_sdk_path)
  return utils.join {dart_sdk_path, "bin", "snapshots", "analysis_server.dart.snapshot"}
end

function M.setup(user_config)
  local config = (user_config and user_config.lsp) and user_config.lsp or {}
  if M.initialised then
    return utils.echomsg [[DartLS has already been setup!]]
  end
  local success, lspconfig = pcall(require, "lspconfig")
  if not success or not lspconfig then
    utils.echomsg("You must have the neovim/nvim-lspconfig module installed", "Error")
    return
  end

  local cfg = {
    init_options = {
      closingLabels = true,
      outline = true,
      flutterOutline = true
    },
    handlers = {
      ["dart/textDocument/publishClosingLabels"] = labels.closing_tags,
      ["dart/textDocument/publishOutline"] = outline.document_outline,
      ["dart/textDocument/publishFlutterOutline"] = outline.flutter_outline
    }
  }
  if user_config.experimental.lsp_derive_paths then
    local executable = require("flutter-tools.executable")
    local dart_sdk_path = executable.dart_sdk_root_path()
    cfg.cmd = {executable.dart_bin_name, analysis_server_snapshot_path(dart_sdk_path), "--lsp"}
  end

  config = vim.tbl_deep_extend("force", cfg, config)
  lspconfig.dartls.setup(config)
  M.initialised = true
end

return M
