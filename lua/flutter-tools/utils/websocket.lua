local bit = require("bit")

local uv = vim.uv

local M = {}

local OPCODE = {
  CONTINUATION = 0x0,
  TEXT = 0x1,
  CLOSE = 0x8,
  PING = 0x9,
  PONG = 0xA,
}

local CONNECT_TIMEOUT_MS = 5000

-- string.char(unpack(t)) is limited by the number of arguments Lua accepts
local CHUNK_SIZE = 4096

---@param bytes integer[]
---@return string
local function bytes_to_string(bytes)
  local parts = {}
  for i = 1, #bytes, CHUNK_SIZE do
    parts[#parts + 1] = string.char(unpack(bytes, i, math.min(i + CHUNK_SIZE - 1, #bytes)))
  end
  return table.concat(parts)
end

---@param value integer
---@param count integer
---@return string
local function big_endian(value, count)
  local bytes = {}
  for i = count, 1, -1 do
    bytes[i] = value % 256
    value = math.floor(value / 256)
  end
  return bytes_to_string(bytes)
end

---@param count integer
---@return integer[]
local function random_bytes(count)
  local bytes = {}
  for i = 1, count do
    bytes[i] = math.random(0, 255)
  end
  return bytes
end

---@param opcode integer
---@param payload string
---@return string
function M.encode_frame(opcode, payload)
  local len = #payload
  local header
  if len < 126 then
    header = string.char(0x80 + opcode, 0x80 + len)
  elseif len < 0x10000 then
    header = string.char(0x80 + opcode, 0x80 + 126) .. big_endian(len, 2)
  else
    header = string.char(0x80 + opcode, 0x80 + 127) .. big_endian(len, 8)
  end
  local mask = random_bytes(4)
  local masked = {}
  for i = 1, len do
    masked[i] = bit.bxor(payload:byte(i), mask[(i - 1) % 4 + 1])
  end
  return header .. bytes_to_string(mask) .. bytes_to_string(masked)
end

---Decodes as many complete frames as `buffer` holds.
---@param buffer string
---@return {fin: boolean, opcode: integer, payload: string}[] frames
---@return string rest bytes belonging to an incomplete frame
function M.decode_frames(buffer)
  local frames = {}
  local pos = 1
  while true do
    if #buffer - pos + 1 < 2 then break end
    local b1, b2 = buffer:byte(pos, pos + 1)
    local offset = pos + 2
    local len = b2 % 128
    if len == 126 then
      if #buffer < offset + 1 then break end
      local h, l = buffer:byte(offset, offset + 1)
      len = h * 256 + l
      offset = offset + 2
    elseif len == 127 then
      if #buffer < offset + 7 then break end
      len = 0
      for i = 0, 7 do
        len = len * 256 + buffer:byte(offset + i)
      end
      offset = offset + 8
    end
    local mask
    if b2 >= 128 then
      if #buffer < offset + 3 then break end
      mask = { buffer:byte(offset, offset + 3) }
      offset = offset + 4
    end
    if #buffer < offset + len - 1 then break end
    local payload = buffer:sub(offset, offset + len - 1)
    if mask then
      local bytes = {}
      for i = 1, len do
        bytes[i] = bit.bxor(payload:byte(i), mask[(i - 1) % 4 + 1])
      end
      payload = bytes_to_string(bytes)
    end
    frames[#frames + 1] = { fin = b1 >= 128, opcode = b1 % 16, payload = payload }
    pos = offset + len
  end
  return frames, buffer:sub(pos)
end

---@class flutter.WebSocket
---@field private tcp uv.uv_tcp_t
---@field private closed boolean
local WebSocket = {}
WebSocket.__index = WebSocket

---@param text string
function WebSocket:send(text)
  if self.closed then return end
  self.tcp:write(M.encode_frame(OPCODE.TEXT, text))
end

function WebSocket:close()
  if self.closed then return end
  self.closed = true
  if not self.tcp:is_closing() then
    self.tcp:write(M.encode_frame(OPCODE.CLOSE, ""))
    self.tcp:shutdown(function() self.tcp:close() end)
  end
end

---@class flutter.WebSocketOpts
---@field on_open fun(ws: flutter.WebSocket)
---@field on_message fun(text: string)
---@field on_close fun(err: string?)

---Connects to a `ws://` url. Callbacks are invoked on the main loop.
---@param url string
---@param opts flutter.WebSocketOpts
function M.connect(url, opts)
  local host, port, resource = url:match("^ws://([^:/]+):(%d+)(/?.*)$")
  if not host then return opts.on_close("Unsupported websocket url: " .. url) end
  if resource == "" then resource = "/" end

  local on_open = vim.schedule_wrap(opts.on_open)
  local on_message = vim.schedule_wrap(opts.on_message)
  local on_close = vim.schedule_wrap(opts.on_close)

  local tcp = assert(uv.new_tcp())
  local timer = assert(uv.new_timer())
  local ws = setmetatable({ tcp = tcp, closed = false }, WebSocket)

  local function fail(err)
    if not timer:is_closing() then timer:close() end
    if not tcp:is_closing() then tcp:close() end
    if ws.closed then return end
    ws.closed = true
    on_close(err)
  end

  timer:start(CONNECT_TIMEOUT_MS, 0, function() fail("Timed out connecting to " .. url) end)

  local function handshake()
    local key = vim.base64.encode(bytes_to_string(random_bytes(16)))
    tcp:write(table.concat({
      ("GET %s HTTP/1.1"):format(resource),
      ("Host: %s:%s"):format(host, port),
      "Upgrade: websocket",
      "Connection: Upgrade",
      "Sec-WebSocket-Key: " .. key,
      "Sec-WebSocket-Version: 13",
      "",
      "",
    }, "\r\n"))

    local buffer = ""
    local handshake_done = false
    local fragments = {}

    tcp:read_start(function(read_err, chunk)
      if read_err then return fail(read_err) end
      if not chunk then return fail(nil) end
      buffer = buffer .. chunk

      if not handshake_done then
        local header_end = buffer:find("\r\n\r\n", 1, true)
        if not header_end then return end
        local status = buffer:match("^HTTP/1%.1 (%d+)")
        if status ~= "101" then
          return fail("Websocket handshake failed: " .. buffer:sub(1, header_end))
        end
        handshake_done = true
        timer:close()
        buffer = buffer:sub(header_end + 4)
        on_open(ws)
      end

      local frames
      frames, buffer = M.decode_frames(buffer)
      for _, frame in ipairs(frames) do
        if frame.opcode == OPCODE.PING then
          tcp:write(M.encode_frame(OPCODE.PONG, frame.payload))
        elseif frame.opcode == OPCODE.CLOSE then
          ws:close()
          on_close(nil)
          return
        elseif frame.opcode == OPCODE.TEXT or frame.opcode == OPCODE.CONTINUATION then
          fragments[#fragments + 1] = frame.payload
          if frame.fin then
            local message = table.concat(fragments)
            fragments = {}
            on_message(message)
          end
        end
      end
    end)
  end

  uv.getaddrinfo(host, port, { socktype = "stream" }, function(resolve_err, addresses)
    if resolve_err or not addresses or #addresses == 0 then
      return fail("Unable to resolve " .. host)
    end
    if ws.closed then return end
    tcp:connect(addresses[1].addr, addresses[1].port, function(connect_err)
      if connect_err then return fail(connect_err) end
      handshake()
    end)
  end)

  return ws
end

return M
