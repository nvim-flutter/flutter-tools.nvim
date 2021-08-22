local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")

local api = vim.api
local lsp = vim.lsp
local fn = vim.fn
local fmt = string.format

local FILETYPE = "dart"

local M = {
  lsps = {},
}

local function analysis_server_snapshot_path(sdk_path)
  return path.join(sdk_path, "bin", "snapshots", "analysis_server.dart.snapshot")
end

---Merge a set of default configurations with a user's own settings
---NOTE: a user can specify a function in which case this will be used
---to determine how to merge the defaults with a user's config
---@param default table
---@param user table|function
---@return table
local function merge_config(default, user)
  if type(user) == "function" then
    return user(default)
  end
  if not user or vim.tbl_isempty(user) then
    return default
  end
  return vim.tbl_deep_extend("force", default or {}, user or {})
end

local function create_debug_log(level)
  return function(msg)
    local levels = require("flutter-tools.config").debug_levels
    if level <= levels.DEBUG then
      utils.notify(msg)
    end
  end
end

---Create default config for dartls
---@param opts table
---@return table
local function get_defaults(opts)
  local flutter_sdk_path = opts.flutter_sdk
  local config = {
    init_options = {
      onlyAnalyzeProjectsWithOpenFiles = true,
      suggestFromUnimportedLibraries = true,
      closingLabels = true,
      outline = true,
      flutterOutline = true,
    },
    settings = {
      dart = {
        completeFunctionCalls = true,
        showTodos = true,
        analysisExcludedFolders = {
          path.join(flutter_sdk_path, "packages"),
          path.join(flutter_sdk_path, ".pub-cache"),
        },
      },
    },
    handlers = {
      ["dart/textDocument/publishClosingLabels"] = require("flutter-tools.labels").closing_tags,
      ["dart/textDocument/publishOutline"] = require("flutter-tools.outline").document_outline,
      ["dart/textDocument/publishFlutterOutline"] = require("flutter-tools.guides").widget_guides,
    },
    capabilities = (function()
      local capabilities = lsp.protocol.make_client_capabilities()
      capabilities.workspace.configuration = true
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      -- @see: https://github.com/hrsh7th/nvim-compe#how-to-use-lsp-snippet
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
        },
      }
      return capabilities
    end)(),
  }
  return config
end

---This was heavily inspired by nvim-metals implementation of the attach functionality
---@return boolean
function M.attach()
  local conf = require("flutter-tools.config").get()
  local user_config = conf.lsp
  local debug_log = create_debug_log(user_config.debug)

  debug_log("attaching LSP")

  local config = utils.merge({ name = "dartls" }, user_config)

  local bufnr = api.nvim_get_current_buf()

  -- Check to see if dartls is already attached, and if so attatch
  for _, buf in pairs(vim.fn.getbufinfo({ bufloaded = true })) do
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

  config.filetypes = { FILETYPE }

  local executable = require("flutter-tools.executable")
  --- TODO if a user specifies a command we do not need to call
  --- executable.dart_sdk_root_path
  executable.get(function(paths)
    local defaults = get_defaults({ flutter_sdk = paths.flutter_sdk })
    local root_path = paths.dart_sdk
    debug_log(fmt("dart_sdk_path: %s", root_path))

    config.cmd = config.cmd
      or {
        executable.dart_bin_name,
        analysis_server_snapshot_path(root_path),
        "--lsp",
      }
    config.root_patterns = config.root_patterns or { ".git", "pubspec.yaml" }

    local current_dir = fn.expand("%:p:h")
    config.root_dir = path.find_root(config.root_patterns, current_dir) or current_dir

    config.capabilities = merge_config(defaults.capabilities, config.capabilities)
    config.init_options = merge_config(defaults.init_options, config.init_options)
    config.handlers = merge_config(defaults.handlers, config.handlers)
    config.settings = merge_config(defaults.settings, { dart = config.settings })

    config.on_init = function(client, _)
      return client.notify("workspace/didChangeConfiguration", { settings = config.settings })
    end

    local client_id = M.lsps[config.root_dir]
    if not client_id then
      client_id = lsp.start_client(config)
      M.lsps[config.root_dir] = client_id
    end

    lsp.buf_attach_client(bufnr, client_id)
  end)
end

return M
