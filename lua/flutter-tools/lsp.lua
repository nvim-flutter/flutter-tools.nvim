local utils = require "flutter-tools/utils"
local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"

local fn = vim.fn

local M = {
  initialised = false
}

local bin_name = "dart"

local function find_dart_sdk_root_path(user_bin_path)
  if user_bin_path then
    return user_bin_path .. "/cache/dart-sdk/bin/dart"
  elseif fn.executable("flutter") == 1 then
    local flutter_path = fn.resolve(fn.exepath("flutter"))
    local flutter_bin = fn.fnamemodify(flutter_path, ":h")
    return flutter_bin.."/cache/dart-sdk/bin/dart"
  elseif fn.executable("dart") == 1 then
    return fn.resolve(fn.exepath("dart"))
  else
    return ''
  end
end

local function analysis_server_snapshot_path()
  local dart_sdk_root_path = fn.fnamemodify(find_dart_sdk_root_path(), ":h")
  local snapshot = dart_sdk_root_path.."/snapshots/analysis_server.dart.snapshot"

  if fn.has("win32") == 1 or fn.has("win64") == 1 then
    snapshot = snapshot:gsub("/", "\\")
  end

  return snapshot
end

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

  local c = require('flutter-tools.config').get()
  local cfg = {
    cmd = {bin_name, analysis_server_snapshot_path(c.flutter_path), "--lsp"};
    flags = {allow_incremental_sync = true},
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

  config = vim.tbl_deep_extend("force", cfg, config)
  lspconfig.dartls.setup(config)
  M.initialised = true
end

return M
