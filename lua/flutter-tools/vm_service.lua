--- VM Service WebSocket client for Flutter/Dart debugging
--- WebSocket framing per RFC 6455:
--- Client frames must be masked with a 4-byte key
--- Frame format: [FIN/opcode][mask/length][mask-key][payload]
local uv = vim.uv or vim.loop

local M = {}

local OPCODE_TEXT = 1
local OPCODE_CLOSE = 8
local OPCODE_PING = 9

local tcp = nil
local connected = false
local handshake_complete = false
local request_id = 0
local pending_requests = {}
local event_handlers = {}
local read_buffer = ""

local function generate_handshake(host, port, path)
  local lines = {
    "GET " .. path .. " HTTP/1.1",
    "Host: " .. host .. ":" .. port,
    "Upgrade: websocket",
    "Connection: Upgrade",
    "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
    "Sec-WebSocket-Version: 13",
    "",
    "",
  }
  return table.concat(lines, "\r\n")
end

local function generate_mask_key()
  return {
    math.random(0, 255),
    math.random(0, 255),
    math.random(0, 255),
    math.random(0, 255),
  }
end

local function mask_payload(payload, key)
  local masked = {}
  for i = 1, #payload do
    local byte = string.byte(payload, i, i)
    local mask_byte = key[((i - 1) % 4) + 1]
    table.insert(masked, string.char(bit.bxor(byte, mask_byte)))
  end
  return table.concat(masked, "")
end

local function create_frame(payload)
  local key = generate_mask_key()
  local len = #payload
  local frame = {}

  table.insert(frame, string.char(0x81))

  if len < 126 then
    table.insert(frame, string.char(0x80 + len))
  elseif len < 65536 then
    table.insert(frame, string.char(0x80 + 126))
    table.insert(frame, string.char(bit.rshift(len, 8)))
    table.insert(frame, string.char(bit.band(len, 0xFF)))
  else
    table.insert(frame, string.char(0x80 + 127))
    for i = 7, 0, -1 do
      table.insert(frame, string.char(bit.band(bit.rshift(len, i * 8), 0xFF)))
    end
  end

  for _, k in ipairs(key) do
    table.insert(frame, string.char(k))
  end

  table.insert(frame, mask_payload(payload, key))

  return table.concat(frame, "")
end

local function parse_frame(data)
  if #data < 2 then return nil, data end

  local b1 = string.byte(data, 1)
  local b2 = string.byte(data, 2)

  local opcode = bit.band(b1, 0x0F)
  local payload_len = bit.band(b2, 0x7F)

  local header_len = 2
  if payload_len == 126 then
    if #data < 4 then return nil, data end
    payload_len = bit.lshift(string.byte(data, 3), 8) + string.byte(data, 4)
    header_len = 4
  elseif payload_len == 127 then
    if #data < 10 then return nil, data end
    payload_len = 0
    for i = 3, 10 do
      payload_len = bit.lshift(payload_len, 8) + string.byte(data, i)
    end
    header_len = 10
  end

  local has_mask = bit.band(b2, 0x80) > 0
  if has_mask then header_len = header_len + 4 end

  local total_len = header_len + payload_len
  if #data < total_len then return nil, data end

  local payload = data:sub(header_len + 1, total_len)
  local remaining = data:sub(total_len + 1)

  return { opcode = opcode, payload = payload }, remaining
end

local function handle_message(message)
  local ok, data = pcall(vim.json.decode, message)
  if not ok then return end

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

function M.connect(uri, on_connect, on_error)
  if connected then M.disconnect() end

  local host, port, path = parse_uri(uri)
  if not host or not port then
    if on_error then on_error("Invalid URI: " .. uri) end
    return
  end

  tcp = uv.new_tcp()
  handshake_complete = false
  read_buffer = ""

  tcp:connect(host, port, function(err)
    if err then
      vim.schedule(function()
        if on_error then on_error("Connection failed: " .. tostring(err)) end
      end)
      return
    end

    tcp:write(generate_handshake(host, port, path))

    tcp:read_start(function(read_err, chunk)
      if read_err then
        vim.schedule(function()
          if on_error then on_error("Read error: " .. tostring(read_err)) end
        end)
        M.disconnect()
        return
      end

      if not chunk then
        M.disconnect()
        return
      end

      if not handshake_complete then
        if chunk:match("HTTP/1.1 101") then
          handshake_complete = true
          connected = true
          vim.schedule(function()
            if on_connect then on_connect() end
          end)
        end
        return
      end

      read_buffer = read_buffer .. chunk
      while true do
        local frame, remaining = parse_frame(read_buffer)
        if not frame then break end
        read_buffer = remaining

        if frame.opcode == OPCODE_TEXT then
          handle_message(frame.payload)
        elseif frame.opcode == OPCODE_PING then
          local pong = string.char(0x8A, 0x80 + #frame.payload)
            .. mask_payload(frame.payload, generate_mask_key())
          tcp:write(pong)
        elseif frame.opcode == OPCODE_CLOSE then
          M.disconnect()
          return
        end
      end
    end)
  end)
end

function M.request(method, params, callback)
  if not connected or not tcp then
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

  tcp:write(create_frame(message))
end

function M.stream_listen(stream_id, handler, callback)
  event_handlers[stream_id] = handler
  M.request("streamListen", { streamId = stream_id }, callback)
end

function M.is_connected() return connected end

function M.disconnect()
  connected = false
  handshake_complete = false

  for _, callback in pairs(pending_requests) do
    vim.schedule(function() callback("Service connection closed", nil) end)
  end
  pending_requests = {}
  event_handlers = {}
  read_buffer = ""

  if tcp then
    if not tcp:is_closing() then
      tcp:read_stop()
      tcp:close()
    end
    tcp = nil
  end
end

return M
