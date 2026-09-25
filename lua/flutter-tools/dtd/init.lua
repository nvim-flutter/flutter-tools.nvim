local lazy = require("flutter-tools.lazy")
local client = lazy.require("flutter-tools.dtd.client") ---@module "flutter-tools.dtd.client"
local lsp_utils = lazy.require("flutter-tools.lsp.utils") ---@module "flutter-tools.lsp.utils"
local lsp = lazy.require("flutter-tools.lsp") ---@module "flutter-tools.lsp"

--- Connects Neovim to the Dart Tooling Daemon the way Dart-Code does in
--- src/extension/dart/tooling_daemon.ts: shares the workspace roots and the analysis server,
--- and provides the `Editor` service that tools such as the widget previewer call.
local M = {}

local api = vim.api
local uv = vim.uv

local EDITOR = "Editor"
local ACTIVE_LOCATION_DELAY_MS = 200
local LSP_INIT_POLL_MS = 100
local LSP_INIT_TIMEOUT_MS = 30000
local LSP_START_TIMEOUT_MS = 10000
local ALREADY_CONNECTED_TO_DTD = -32015
local UNSUPPORTED_URI_SCHEME = 144

local augroup = api.nvim_create_augroup("FlutterToolsDtd", { clear = true })

---@type string?
local integrated_uri = nil

---DTD uri each dartls client is attached to, or false if it is attached elsewhere.
---@type table<integer, string|false>
local lsp_connections = {}

---Callbacks waiting on a connection attempt that is still in flight, per client.
---@type table<integer, fun()[]>
local lsp_connecting = {}

---@type table
local active_location = { selections = {} }

---@type uv.uv_timer_t?
local location_timer = nil

---@param win integer
---@return boolean
local function is_real_editor(win)
  local buf = api.nvim_win_get_buf(win)
  return api.nvim_win_get_config(win).relative == "" and vim.bo[buf].buftype == ""
end

---@param buf integer
---@param row integer 1-based
---@param col integer 0-based byte column
local function position(buf, row, col)
  local line = api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  return { line = row - 1, character = vim.str_utfindex(line, "utf-16", math.min(col, #line)) }
end

---@param buf integer
---@return string?
local function file_uri(buf)
  local name = api.nvim_buf_get_name(buf)
  if name == "" or name:match("^%a[%w+.-]*://") then return nil end
  return vim.uri_from_fname(name)
end

---@param win integer
local function get_active_location(win)
  local buf = api.nvim_win_get_buf(win)
  local cursor = api.nvim_win_get_cursor(win)
  local active = position(buf, cursor[1], cursor[2])
  local anchor = active
  if api.nvim_get_mode().mode:match("^[vV\22]") then
    local visual_start = vim.fn.getpos("v")
    anchor = position(buf, visual_start[2], visual_start[3] - 1)
  end
  local uri = file_uri(buf)
  return {
    textDocument = uri and { uri = uri, version = vim.b[buf].changedtick } or nil,
    selections = { { active = active, anchor = anchor } },
  }
end

local function update_active_location()
  local win = api.nvim_get_current_win()
  if not is_real_editor(win) then return end
  active_location = get_active_location(win)
  client.post_event(EDITOR, "activeLocationChanged", active_location)
end

local function queue_active_location_update()
  if not location_timer then location_timer = assert(uv.new_timer()) end
  location_timer:stop()
  location_timer:start(ACTIVE_LOCATION_DELAY_MS, 0, vim.schedule_wrap(update_active_location))
end

---@return integer
local function editor_window()
  local current = api.nvim_get_current_win()
  if is_real_editor(current) then return current end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_real_editor(win) then return win end
  end
  return current
end

---Opens `uri` at a 1-based `line` and `column`, falling back to the first non-blank character
---when the column is missing or past the end of the line.
---@param params {uri: string, line: integer?, column: integer?}
local function navigate_to_code(params)
  local fname = vim.uri_to_fname(params.uri)
  local buf = vim.fn.bufadd(fname)
  vim.fn.bufload(buf)
  local row = math.max((params.line or 1) - 1, 0)
  local text = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local character
  if params.line and params.column and params.column <= vim.str_utfindex(text, "utf-16") then
    character = math.max(params.column - 1, 0)
  else
    character = vim.str_utfindex(text, "utf-16", (text:find("%S") or 1) - 1)
  end
  local pos = { line = row, character = character }
  api.nvim_set_current_win(editor_window())
  vim.lsp.util.show_document(
    { uri = params.uri, range = { start = pos, ["end"] = pos } },
    "utf-16",
    { focus = true }
  )
end

local function register_editor_service()
  client.register_service(
    EDITOR,
    "getActiveLocation",
    function() return vim.tbl_extend("force", active_location, { type = "ActiveLocation" }) end
  )
  client.register_service(EDITOR, "navigateToCode", function(params)
    local scheme = params.uri and params.uri:match("^(%a[%w+.-]*):")
    if scheme ~= "file" then
      error({
        code = UNSUPPORTED_URI_SCHEME,
        message = ("Unsupported URI scheme: %s"):format(scheme),
      })
    end
    vim.schedule(function() navigate_to_code(params) end)
    return { type = "Success" }
  end)
end

---@return vim.lsp.Client[]
local function dartls_clients() return vim.lsp.get_clients({ name = lsp_utils.SERVER_NAME }) end

local function send_workspace_roots()
  local roots = {}
  for _, lsp_client in ipairs(dartls_clients()) do
    for _, folder in ipairs(lsp_client.workspace_folders or {}) do
      roots[folder.uri] = true
    end
    if lsp_client.root_dir then roots[vim.uri_from_fname(lsp_client.root_dir)] = true end
  end
  client.request(
    "FileSystem.setIDEWorkspaceRoots",
    { secret = client.secret(), roots = vim.tbl_keys(roots) }
  )
end

---@param lsp_client vim.lsp.Client
---@param callback fun()
local function when_initialized(lsp_client, callback)
  if lsp_client.initialized then return callback() end
  local timer = assert(uv.new_timer())
  local elapsed = 0
  timer:start(
    LSP_INIT_POLL_MS,
    LSP_INIT_POLL_MS,
    vim.schedule_wrap(function()
      elapsed = elapsed + LSP_INIT_POLL_MS
      if lsp_client.initialized or lsp_client:is_stopped() or elapsed >= LSP_INIT_TIMEOUT_MS then
        timer:stop()
        timer:close()
        callback()
      end
    end)
  )
end

---An analysis server can only attach to one DTD in its lifetime, and rejects requests until it
---is initialized.
---@param lsp_client vim.lsp.Client
---@param callback fun()
local function connect_lsp(lsp_client, callback)
  local id = lsp_client.id
  if lsp_connections[id] ~= nil then return callback() end
  if lsp_connecting[id] then return table.insert(lsp_connecting[id], callback) end
  lsp_connecting[id] = { callback }

  local function finish()
    local callbacks = lsp_connecting[id] or {}
    lsp_connecting[id] = nil
    for _, waiting in ipairs(callbacks) do
      waiting()
    end
  end

  when_initialized(lsp_client, function()
    if not lsp_client.initialized then return finish() end
    local uri = client.uri()
    lsp_client:request("dart/connectToDtd", { uri = uri }, function(err)
      if not err then
        lsp_connections[id] = uri
      elseif err.code == ALREADY_CONNECTED_TO_DTD then
        lsp_connections[id] = false
      end
      finish()
    end)
  end)
end

---The plugin starts dartls asynchronously, so a Dart buffer may not have its client yet.
---@param callback fun()
local function when_dartls_started(callback)
  if #dartls_clients() > 0 or vim.bo.filetype ~= "dart" then return callback() end
  local done = false
  local function finish()
    if done then return end
    done = true
    callback()
  end
  api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(args)
      local lsp_client = vim.lsp.get_client_by_id(args.data.client_id)
      if lsp_client and lsp_client.name == lsp_utils.SERVER_NAME then
        finish()
        return true
      end
    end,
  })
  vim.defer_fn(finish, LSP_START_TIMEOUT_MS)
end

---@param callback fun()
local function connect_all_lsps(callback)
  local remaining = 1
  local function done()
    remaining = remaining - 1
    if remaining == 0 then callback() end
  end
  for _, lsp_client in ipairs(dartls_clients()) do
    remaining = remaining + 1
    connect_lsp(lsp_client, done)
  end
  done()
end

local function create_autocmds()
  api.nvim_clear_autocmds({ group = augroup })
  api.nvim_create_autocmd(
    { "BufEnter", "WinEnter", "CursorMoved", "CursorMovedI", "ModeChanged" },
    {
      group = augroup,
      callback = queue_active_location_update,
    }
  )
  api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(args)
      local lsp_client = vim.lsp.get_client_by_id(args.data.client_id)
      if not lsp_client or lsp_client.name ~= lsp_utils.SERVER_NAME then return end
      connect_lsp(lsp_client, function() end)
      send_workspace_roots()
    end,
  })
end

---Starts the daemon, if needed, and waits until the dartls clients are attached to it.
---@param callback fun(err: string?)
function M.start(callback)
  client.start(function(err)
    if err then return callback(err) end
    if integrated_uri ~= client.uri() then
      integrated_uri = client.uri()
      register_editor_service()
      create_autocmds()
      send_workspace_roots()
      update_active_location()
    end
    when_dartls_started(function()
      connect_all_lsps(function() callback(nil) end)
    end)
  end)
end

function M.stop()
  api.nvim_clear_autocmds({ group = augroup })
  if location_timer then location_timer:stop() end
  integrated_uri = nil
  client.stop()
end

---@return string?
function M.uri() return client.uri() end

---@return vim.lsp.Client[]
local function shared_lsp_clients()
  return vim.tbl_filter(
    function(lsp_client) return lsp_connections[lsp_client.id] == client.uri() end,
    dartls_clients()
  )
end

---Tools query the shared analysis server once on startup, and it answers with no results until
---its first analysis has finished, so they must not start before that.
---@param callback fun()
function M.when_analyzed(callback)
  local remaining = 1
  local function done()
    remaining = remaining - 1
    if remaining == 0 then callback() end
  end
  for _, lsp_client in ipairs(shared_lsp_clients()) do
    remaining = remaining + 1
    lsp.when_analyzed(lsp_client.id, done)
  end
  done()
end

---@param lsp_client vim.lsp.Client
---@param dir string
---@return boolean
local function analyzes(lsp_client, dir)
  local real_dir = uv.fs_realpath(dir) or dir
  local roots = vim.tbl_map(
    function(folder) return vim.uri_to_fname(folder.uri) end,
    lsp_client.workspace_folders or {}
  )
  if lsp_client.root_dir then table.insert(roots, lsp_client.root_dir) end
  for _, root in ipairs(roots) do
    if vim.fs.relpath(uv.fs_realpath(root) or root, real_dir) then return true end
  end
  return false
end

---Whether tools connecting to the daemon would analyze `dir` correctly: either a dartls client
---serving `dir` provides the analysis server, or none does and the tool starts its own.
---@param dir string
---@return boolean
function M.can_analyze(dir)
  local shared = shared_lsp_clients()
  for _, lsp_client in ipairs(shared) do
    if analyzes(lsp_client, dir) then return true end
  end
  return #shared == 0
end

return M
