---@diagnostic disable: need-check-nil
describe("Devices - ", function()
  describe("parsing tests - ", function()
    local devices = require("flutter-tools.devices")
    local parse = devices.parse
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

    it("should build selection entries for parsed devices", function()
      local entries = devices.to_selection_entries({ "linux • Linux • linux-x64 • linux" })

      assert.equal(1, #entries)
      assert.equal(" linux  • linux-x64 ", entries[1].text)
      assert.equal("Linux", entries[1].data.id)
    end)

    it("should fall back to raw output when no devices are parsed", function()
      local result = {
        "No supported devices connected.",
        "Run 'flutter emulators' to list and start any available device emulators.",
      }
      local entries = devices.to_selection_entries(result)

      assert.equal(2, #entries)
      assert.equal(result[1], entries[1].text)
      assert.is_nil(entries[1].data)
      assert.equal(result[2], entries[2].text)
      assert.is_nil(entries[2].data)
    end)

    it("should return an empty list when there is no output", function()
      assert.same({}, devices.to_selection_entries({}))
      assert.same({}, devices.to_selection_entries(nil))
    end)
  end)
end)
