local websocket = require("flutter-tools.utils.websocket")

local TEXT = 0x1

describe("websocket frames", function()
  for _, size in ipairs({ 0, 5, 125, 126, 65535, 65536, 70000 }) do
    it(("round-trips a %d byte payload"):format(size), function()
      local payload = string.rep("ab", math.ceil(size / 2)):sub(1, size)
      local frames, rest = websocket.decode_frames(websocket.encode_frame(TEXT, payload))
      assert.are.same({ { fin = true, opcode = TEXT, payload = payload } }, frames)
      assert.are.equal("", rest)
    end)
  end

  it("keeps an incomplete frame for the next read", function()
    local frame = websocket.encode_frame(TEXT, string.rep("x", 300))
    local frames, rest = websocket.decode_frames(frame:sub(1, 100))
    assert.are.same({}, frames)
    frames, rest = websocket.decode_frames(rest .. frame:sub(101))
    assert.are.equal(300, #frames[1].payload)
    assert.are.equal("", rest)
  end)

  it("decodes several frames from one read", function()
    local data = websocket.encode_frame(TEXT, "one") .. websocket.encode_frame(TEXT, "two")
    local frames = websocket.decode_frames(data)
    assert.are.same({ "one", "two" }, vim.tbl_map(function(f) return f.payload end, frames))
  end)

  it("decodes unmasked server frames", function()
    local frames = websocket.decode_frames(string.char(0x81, 0x02) .. "hi")
    assert.are.equal("hi", frames[1].payload)
  end)
end)
