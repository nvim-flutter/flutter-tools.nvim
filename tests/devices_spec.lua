---@diagnostic disable: need-check-nil
describe("Devices - ", function()
  describe("parsing tests - ", function()
    local parse = require("flutter-tools.devices").parse
    it("should correctly parse flutter emulators output", function()
      local output = parse("apple_ios_simulator • iOS Simulator        • Apple  • ios", 1)
      assert.equal(output.id, "apple_ios_simulator")
      assert.equal(output.name, "iOS Simulator")
      assert.equal(output.platform, "Apple")
      assert.equal(output.system, "ios")
    end)

    it("should correctly parse emulators despite missing values", function()
      local output = parse("default     • default     •  • android", 1)
      assert.equal(output.id, "default")
      assert.equal(output.name, "default")
      assert.equal(output.platform, "")
      assert.equal(output.system, "android")
    end)

    it("should skip `crashdata` lines", function()
      local output = parse(
        [[INFO    | Storing crashdata in: /tmp/android-ts/emu-crash-34.2.14.db, detection is enabled for process: 46675 •
INFO    | Storing crashdata in: /tmp/android-ts/emu-crash-34.2.14.db, detection is enabled for process: 46675 •
• android]],
        1
      )
      assert.is_nil(output)
    end)
  end)
end)
