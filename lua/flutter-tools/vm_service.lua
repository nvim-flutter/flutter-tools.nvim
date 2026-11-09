--- VM Service WebSocket client for Flutter/Dart debugging
local lazy = require("flutter-tools.lazy")
local websocket = require("flutter-tools.utils.websocket")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"

local M = {}

local MAX_RECONNECT_ATTEMPTS = 10
local RECONNECT_DELAYS_MS = { 300, 600, 1200, 2500, 5000 }

---@type flutter.WebSocket?
local socket = nil
local connected = false
local request_id = 0
local pending_requests = {}
local event_handlers = {}

-- Bumped every time the socket changes so callbacks of an old socket are ignored
local generation = 0

---@class flutter.VmServiceTarget
---@field url string
---@field on_connect fun()?
---@field on_error fun(err: string)?
---@field attempts integer
---@field opened boolean

---@type flutter.VmServiceTarget?
local target = nil

local function handle_message(message)
  local ok, data = pcall(vim.json.decode, message)
  if not ok or type(data) ~= "table" then return end

  if data.id and pending_requests[data.id] then
    local callback = pending_requests[data.id]
    pending_requests[data.id] = nil
    vim.schedule(function() callback(data.error, data.result) end)
    return
  end

  if data.method == "streamNotify" and data.params then
    local stream_id = data.params.streamId
    local event = data.params.event
    if event_handlers[stream_id] then
      vim.schedule(function() event_handlers[stream_id](event) end)
    end
  end
end

local function parse_uri(uri)
  local protocol, rest = uri:match("^(wss?)://(.+)$")
  if not protocol then
    protocol, rest = uri:match("^(https?)://(.+)$")
  end
  if not rest then return nil, nil, nil end

  local host_port, path = rest:match("^([^/]+)(/.*)$")
  if not host_port then
    host_port = rest
    path = "/"
  end

  local host, port = host_port:match("^([^:]+):(%d+)$")
  if not host then
    host = host_port
    port = (protocol == "wss" or protocol == "https") and 443 or 80
  end

  if not path:match("/ws$") then path = path:gsub("/$", "") .. "/ws" end

  return host, tonumber(port), path
end

local function fail_pending_requests()
  local callbacks = pending_requests
  pending_requests = {}
  for _, callback in pairs(callbacks) do
    vim.schedule(function() callback("Service connection closed", nil) end)
  end
end

local function close_socket()
  generation = generation + 1
  connected = false
  if socket then socket:close() end
  socket = nil
  fail_pending_requests()
end

local open_socket

-- Retry after losing the connection; once the attempts run out, give up and report the error
local function schedule_reconnect(reason)
  target.attempts = target.attempts + 1
  if target.attempts > MAX_RECONNECT_ATTEMPTS then
    local on_error = target.on_error
    target = nil
    event_handlers = {}
    ui.notify("Lost the connection to the VM service: " .. reason, ui.WARN)
    if on_error then on_error(reason) end
    return
  end
  if target.attempts == 1 then
    ui.notify("Lost the connection to the VM service (" .. reason .. "), reconnecting", ui.WARN)
  end
  local gen = generation
  local delay = RECONNECT_DELAYS_MS[math.min(target.attempts, #RECONNECT_DELAYS_MS)]
  vim.defer_fn(function()
    if target and gen == generation and not socket then open_socket() end
  end, delay)
end

local function on_closed(gen, err)
  if gen ~= generation or not target then return end
  local reason = err or "connection closed"
  close_socket()
  -- Never connected: report the error right away instead of retrying
  if not target.opened then
    local on_error = target.on_error
    target = nil
    if on_error then on_error(reason) end
    return
  end
  schedule_reconnect(reason)
end

local function on_opened(gen, ws)
  if gen ~= generation or not target then return ws:close() end
  socket, connected = ws, true
  target.attempts = 0
  -- Listen again to the streams that were registered before the connection was lost
  for stream_id in pairs(event_handlers) do
    M.request("streamListen", { streamId = stream_id })
  end
  if target.opened then return ui.notify("Reconnected to the VM service", ui.INFO) end
  target.opened = true
  if target.on_connect then target.on_connect() end
end

function open_socket()
  generation = generation + 1
  local gen = generation
  websocket.connect(target.url, {
    on_open = function(ws) on_opened(gen, ws) end,
    on_message = function(text)
      if gen == generation then handle_message(text) end
    end,
    on_close = function(err) on_closed(gen, err) end,
  })
end

---Connects to the VM service and keeps the connection alive: when it drops the client reconnects
---and listens again to every stream registered with `stream_listen`.
---@param uri string
---@param on_connect fun()?
---@param on_error fun(err: string)?
function M.connect(uri, on_connect, on_error)
  M.disconnect()

  local host, port, path = parse_uri(uri)
  if not host or not port then
    if on_error then on_error("Invalid URI: " .. uri) end
    return
  end

  target = {
    url = ("ws://%s:%d%s"):format(host, port, path),
    on_connect = on_connect,
    on_error = on_error,
    attempts = 0,
    opened = false,
  }
  open_socket()
end

function M.request(method, params, callback)
  if not connected or not socket then
    if callback then callback("Not connected", nil) end
    return
  end

  request_id = request_id + 1
  local id = tostring(request_id)

  local message = vim.json.encode({
    jsonrpc = "2.0",
    id = id,
    method = method,
    params = params or {},
  })

  if callback then pending_requests[id] = callback end

  socket:send(message)
end

function M.stream_listen(stream_id, handler, callback)
  event_handlers[stream_id] = handler
  M.request("streamListen", { streamId = stream_id }, callback)
end

function M.is_connected() return connected end

function M.disconnect()
  target = nil
  event_handlers = {}
  close_socket()
end

return M
