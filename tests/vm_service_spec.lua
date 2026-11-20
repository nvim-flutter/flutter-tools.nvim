local websocket = require("flutter-tools.utils.websocket")
local vm_service = require("flutter-tools.vm_service")

local uv = vim.uv
local TEXT = 0x1
local CONTINUATION = 0x0
local HANDSHAKE_RESPONSE = table.concat({
  "HTTP/1.1 101 Switching Protocols",
  "Upgrade: websocket",
  "Connection: Upgrade",
  "",
  "",
}, "\r\n")

-- Server -> client frames are not masked
local function server_frame(payload, opcode, fin)
  local first = (fin == false and 0 or 0x80) + (opcode or TEXT)
  return string.char(first, #payload) .. payload
end

local function notify_event(stream_id, event)
  return vim.json.encode({
    jsonrpc = "2.0",
    method = "streamNotify",
    params = { streamId = stream_id, event = event },
  })
end

---Minimal websocket server. `reply` is called with the connection once the handshake request has
---been read and must answer it.
local function start_server(reply)
  local server = assert(uv.new_tcp())
  assert(server:bind("127.0.0.1", 0))
  local connections = {}
  server:listen(16, function()
    local client = assert(uv.new_tcp())
    server:accept(client)
    local conn = { client = client, requests = {} }
    connections[#connections + 1] = conn
    local buffer, handshaken = "", false
    client:read_start(function(_, chunk)
      if not chunk then return end
      buffer = buffer .. chunk
      if not handshaken then
        local header_end = buffer:find("\r\n\r\n", 1, true)
        if not header_end then return end
        buffer, handshaken = buffer:sub(header_end + 4), true
        if reply then
          reply(conn)
        else
          client:write(HANDSHAKE_RESPONSE)
        end
      end
      local frames
      frames, buffer = websocket.decode_frames(buffer)
      for _, frame in ipairs(frames) do
        if frame.opcode == TEXT then table.insert(conn.requests, vim.json.decode(frame.payload)) end
      end
    end)
  end)
  local function stop()
    for _, conn in ipairs(connections) do
      if not conn.client:is_closing() then conn.client:close() end
    end
    if not server:is_closing() then server:close() end
  end
  return { port = server:getsockname().port, connections = connections, stop = stop }
end

local function uri(server) return ("http://127.0.0.1:%d/token=/"):format(server.port) end

local function listened_streams(conn)
  local streams = {}
  for _, request in ipairs(conn.requests) do
    if request.method == "streamListen" then table.insert(streams, request.params.streamId) end
  end
  return streams
end

describe("vm_service", function()
  local server

  after_each(function()
    vm_service.disconnect()
    if server then server.stop() end
    server = nil
  end)

  it("reports the first connection", function()
    server = start_server()
    local connected = false
    vm_service.connect(uri(server), function() connected = true end)
    assert.is_true(vim.wait(2000, function() return connected end))
    assert.is_true(vm_service.is_connected())
  end)

  it("delivers an event sent together with the handshake response", function()
    local event = notify_event("Debug", { kind = "Inspect" })
    server = start_server(
      function(conn) conn.client:write(HANDSHAKE_RESPONSE .. server_frame(event)) end
    )
    local received
    vm_service.connect(uri(server), function()
      vm_service.stream_listen("Debug", function(e) received = e end)
    end)
    assert.is_true(vim.wait(2000, function() return received ~= nil end))
    assert.are.equal("Inspect", received.kind)
  end)

  it("assembles a message split in several frames", function()
    local event = notify_event("Debug", { kind = "Inspect" })
    local half = math.floor(#event / 2)
    server = start_server(function(conn)
      conn.client:write(HANDSHAKE_RESPONSE)
      conn.client:write(server_frame(event:sub(1, half), TEXT, false))
      conn.client:write(server_frame(event:sub(half + 1), CONTINUATION, true))
    end)
    local received
    vm_service.connect(uri(server), function()
      vm_service.stream_listen("Debug", function(e) received = e end)
    end)
    assert.is_true(vim.wait(2000, function() return received ~= nil end))
    assert.are.equal("Inspect", received.kind)
  end)

  it("reconnects and listens again to its streams when the server drops the connection", function()
    server = start_server()
    local received = {}
    vm_service.connect(uri(server), function()
      vm_service.stream_listen("Debug", function(e) table.insert(received, e.kind) end)
    end)
    assert.is_true(vim.wait(2000, function() return #server.connections == 1 end))
    assert.is_true(
      vim.wait(2000, function() return #listened_streams(server.connections[1]) == 1 end)
    )

    server.connections[1].client:close()

    assert.is_true(vim.wait(5000, function() return #server.connections == 2 end))
    assert.is_true(vim.wait(2000, function() return vm_service.is_connected() end))
    assert.is_true(
      vim.wait(2000, function() return #listened_streams(server.connections[2]) == 1 end)
    )
    assert.are.same({ "Debug" }, listened_streams(server.connections[2]))

    -- Events on the new connection still reach the handler registered before the drop
    server.connections[2].client:write(server_frame(notify_event("Debug", { kind = "Inspect" })))
    assert.is_true(vim.wait(2000, function() return #received == 1 end))
  end)

  it("fails the pending requests when the connection drops", function()
    server = start_server()
    local connected = false
    vm_service.connect(uri(server), function() connected = true end)
    assert.is_true(vim.wait(2000, function() return connected end))
    local err
    vm_service.request("getVM", {}, function(e) err = e end)
    server.connections[1].client:close()
    assert.is_true(vim.wait(2000, function() return err ~= nil end))
    assert.are.equal("Service connection closed", err)
  end)

  it("does not reconnect after disconnect()", function()
    server = start_server()
    local connected = false
    vm_service.connect(uri(server), function() connected = true end)
    assert.is_true(vim.wait(2000, function() return connected end))
    vm_service.disconnect()
    vim.wait(1000)
    assert.are.equal(1, #server.connections)
    assert.is_false(vm_service.is_connected())
  end)

  it("reports an error instead of retrying when it never managed to connect", function()
    server = start_server()
    local port = server.port
    server.stop()
    server = nil
    local calls, err = 0, nil
    vm_service.connect(("http://127.0.0.1:%d/token=/"):format(port), nil, function(e)
      calls, err = calls + 1, e
    end)
    assert.is_true(vim.wait(2000, function() return calls > 0 end))
    vim.wait(1000)
    assert.are.equal(1, calls)
    assert.is_truthy(err)
    assert.is_false(vm_service.is_connected())
  end)
end)
