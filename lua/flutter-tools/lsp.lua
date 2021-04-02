local utils = require("flutter-tools.utils")
local labels = require("flutter-tools.labels")
local outline = require("flutter-tools.outline")
local guides = require("flutter-tools.guides")

local api = vim.api
local lsp = vim.lsp
local fn = vim.fn
local fmt = string.format

local FILETYPE = "dart"

local M = {
  lsps = {}
}

local function analysis_server_snapshot_path(sdk_path)
  return utils.join {sdk_path, "bin", "snapshots", "analysis_server.dart.snapshot"}
end

function M.setup()
  require("flutter-tools.utils").augroup(
    "FlutterToolsLsp",
    {
      {
        events = {"FileType"},
        targets = {"dart"},
        command = "lua require('flutter-tools.lsp').attach()"
      }
    }
  )
end

local function merge_config(default, user)
  return vim.tbl_deep_extend("force", default or {}, user or {})
end

local function create_debug_log(level)
  return function(msg)
    local levels = require("flutter-tools.config").debug_levels
    if level >= levels.DEBUG then
      utils.echomsg(msg)
    end
  end
end

function M.attach()
  local conf = require("flutter-tools.config").get()
  local user_config = conf.lsp or {}
  local debug_log = create_debug_log(user_config.debug)

  debug_log("attaching LSP")

  local config = utils.merge({name = "dartls"}, user_config)

  local bufnr = api.nvim_get_current_buf()
  -- local bufname = api.nvim_buf_get_name(bufnr)

  -- Check to see if dartls is already attached, and if so attatch
  for _, buf in pairs(vim.fn.getbufinfo({bufloaded = true})) do
    if api.nvim_buf_get_option(buf.bufnr, "filetype") == FILETYPE then
      local clients = lsp.buf_get_clients(buf.bufnr)
      for _, client in ipairs(clients) do
        if client.config.name == config.name then
          lsp.buf_attach_client(bufnr, client.id)
          return true
        end
      end
    end
  end

  config.filetypes = {FILETYPE}

  local executable = require("flutter-tools.executable")
  local path = executable.dart_sdk_root_path()

  debug_log(fmt("dart_sdk_path: %s", path))

  config.cmd = {executable.dart_bin_name, analysis_server_snapshot_path(path), "--lsp"}
  config.root_patterns = config.root_patterns or {".git", "pubspec.yaml"}

  -- util.find_root_dir(config.root_patterns, bufname) or
  config.root_dir = fn.expand("%:p:h")
  config.capabilities = merge_config(lsp.protocol.make_client_capabilities(), config.capabilities)
  config.capabilities = merge_config(config.capabilities, {workspace = {configuration = true}})

  config.init_options = {
    onlyAnalyzeProjectsWithOpenFiles = false,
    suggestFromUnimportedLibraries = true,
    closingLabels = true,
    outline = true,
    flutterOutline = true
  }

  config.handlers = {
    ["dart/textDocument/publishClosingLabels"] = labels.closing_tags,
    ["dart/textDocument/publishOutline"] = outline.document_outline,
    ["dart/textDocument/publishFlutterOutline"] = guides.widget_guides
  }

  local settings = config.settings or {}

  config.on_init = function(client, _)
    return client.notify("workspace/didChangeConfiguration", {settings = settings})
  end

  local client_id = M.lsps[config.root_dir]
  if not client_id then
    client_id = lsp.start_client(config)
    M.lsps[config.root_dir] = client_id
  end

  lsp.buf_attach_client(bufnr, client_id)
end

return M
