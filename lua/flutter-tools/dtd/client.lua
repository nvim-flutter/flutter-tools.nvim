local lazy = require("flutter-tools.lazy")
local executable = lazy.require("flutter-tools.executable") ---@module "flutter-tools.executable"
local websocket = lazy.require("flutter-tools.utils.websocket") ---@module "flutter-tools.utils.websocket"

--- JSON-RPC client for a Dart Tooling Daemon (DTD) process owned by this plugin.
--- Mirrors Dart-Code's src/shared/services/tooling_daemon.ts.
local M = {}

local METHOD_NOT_FOUND = -32601
local INTERNAL_ERROR = -32603

---@class flutter.DtdError
---@field code integer
---@field message string

---@type vim.SystemObj?
local process = nil

---@type {uri: string, secret: string}?
local details = nil

---@type flutter.WebSocket?
local socket = nil

---@type fun(err: string?)[]
local on_ready = {}

local next_id = 0

---@type table<integer, fun(err: flutter.DtdError?, result: any)>
local pending = {}

---@type table<string, fun(params: table): table>
local services = {}

local function send(message)
  if socket then socket:send(vim.json.encode(message)) end
end

---@param err string?
local function flush_ready(err)
  local callbacks = on_ready
  on_ready = {}
  for _, callback in ipairs(callbacks) do
    callback(err)
  end
end

local function disconnect()
  if socket then socket:close() end
  socket = nil
  details = nil
  pending = {}
  services = {}
end

---@param message table
local function handle_request(message)
  if message.id == nil then return end
  local handler = services[message.method]
  if not handler then
    return send({
      jsonrpc = "2.0",
      id = message.id,
      error = { code = METHOD_NOT_FOUND, message = "Unknown method " .. message.method },
    })
  end
  local ok, result = pcall(handler, message.params or {})
  if ok then return send({ jsonrpc = "2.0", id = message.id, result = result }) end
  local err = type(result) == "table" and result
    or { code = INTERNAL_ERROR, message = tostring(result) }
  send({ jsonrpc = "2.0", id = message.id, error = err })
end

---@param text string
local function handle_message(text)
  local ok, message = pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
  if not ok or type(message) ~= "table" then return end

  if message.method then
    handle_request(message)
  elseif message.id ~= nil and pending[message.id] then
    local callback = pending[message.id]
    pending[message.id] = nil
    callback(message.error, message.result)
  end
end

---@param daemon {uri: string, secret: string}
local function connect(daemon)
  websocket.connect(daemon.uri, {
    on_open = function(ws)
      socket = ws
      details = daemon
      flush_ready(nil)
    end,
    on_message = handle_message,
    on_close = function(err)
      local was_connected = details ~= nil
      disconnect()
      if not was_connected then
        flush_ready(err or "Connection to the Dart Tooling Daemon closed")
      end
    end,
  })
end

---@param line string
---@return {uri: string, secret: string}?
local function parse_details(line)
  local ok, json = pcall(vim.json.decode, line)
  local daemon = ok and type(json) == "table" and json.tooling_daemon_details
  if type(daemon) == "table" and daemon.uri and daemon.trusted_client_secret then
    return { uri = daemon.uri, secret = daemon.trusted_client_secret }
  end
end

---Starts the daemon and connects to it, or reuses the running one.
---@param callback fun(err: string?)
function M.start(callback)
  if details then return callback(nil) end
  table.insert(on_ready, callback)
  if #on_ready > 1 then return end

  executable.dart(function(dart_bin)
    local stdout = ""
    local found = false
    local ok, obj = pcall(
      vim.system,
      { dart_bin, "tooling-daemon", "--machine" },
      {
        stdout = function(_, data)
          if not data or found then return end
          stdout = stdout .. data
          for line in stdout:gmatch("[^\n]+") do
            local daemon = parse_details(line)
            if daemon then
              found = true
              vim.schedule(function() connect(daemon) end)
              return
            end
          end
        end,
      },
      vim.schedule_wrap(function(result)
        process = nil
        local was_connected = details ~= nil
        disconnect()
        if not was_connected then
          flush_ready(("Dart Tooling Daemon exited with code %d"):format(result.code))
        end
      end)
    )
    if not ok then return flush_ready(tostring(obj)) end
    process = obj
  end)
end

function M.stop()
  disconnect()
  if process then process:kill("sigterm") end
  process = nil
end

---@return string?
function M.uri() return details and details.uri end

---@return string?
function M.secret() return details and details.secret end

---@param method string
---@param params table?
---@param callback fun(err: flutter.DtdError?, result: any)?
function M.request(method, params, callback)
  if not socket then
    if callback then
      callback({ code = INTERNAL_ERROR, message = "Not connected to the Dart Tooling Daemon" })
    end
    return
  end
  next_id = next_id + 1
  pending[next_id] = callback or function() end
  send({ jsonrpc = "2.0", id = next_id, method = method, params = params })
end

---Registers `service.method` for other DTD clients to call. `handler` returns a table with a
---`type` field, or raises a {@link flutter.DtdError}.
---@param service string
---@param method string
---@param handler fun(params: table): table
function M.register_service(service, method, handler)
  M.request("registerService", { service = service, method = method }, function(err)
    if not err then services[service .. "." .. method] = handler end
  end)
end

---@param stream string
---@param kind string
---@param data table
function M.post_event(stream, kind, data)
  M.request("postEvent", { streamId = stream, eventKind = kind, eventData = data })
end

return M
