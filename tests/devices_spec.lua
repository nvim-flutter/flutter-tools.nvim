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

  describe("default device resolution - ", function()
    local devices = require("flutter-tools.devices")

    local function machine_output(entries) return { vim.json.encode(entries) } end

    it("should pick the only supported device", function()
      local device = devices.resolve_default_device(machine_output({
        { name = "macOS", id = "macos", isSupported = true, targetPlatform = "darwin" },
      }))

      assert.equal("macos", device.id)
      assert.equal("macOS", device.name)
      assert.equal("darwin", device.platform)
    end)

    it("should prefer the single ephemeral device over desktop and web", function()
      local device = devices.resolve_default_device(machine_output({
        { name = "iPhone 16", id = "sim-id", isSupported = true, targetPlatform = "ios" },
        { name = "macOS", id = "macos", isSupported = true, targetPlatform = "darwin" },
        { name = "Chrome", id = "chrome", isSupported = true, targetPlatform = "web-javascript" },
      }))

      assert.equal("sim-id", device.id)
    end)

    it("should ignore unsupported devices", function()
      local device = devices.resolve_default_device(machine_output({
        { name = "iPhone 16", id = "sim-id", isSupported = false, targetPlatform = "ios" },
        { name = "macOS", id = "macos", isSupported = true, targetPlatform = "darwin" },
      }))

      assert.equal("macos", device.id)
    end)

    it("should return nil when several ephemeral devices are connected", function()
      local device = devices.resolve_default_device(machine_output({
        { name = "iPhone 16", id = "sim-id", isSupported = true, targetPlatform = "ios" },
        { name = "Pixel 8", id = "emulator-5554", isSupported = true, targetPlatform = "android" },
      }))

      assert.is_nil(device)
    end)

    it("should treat every desktop architecture as non-ephemeral", function()
      local device = devices.resolve_default_device(machine_output({
        {
          name = "Pixel 8",
          id = "emulator-5554",
          isSupported = true,
          targetPlatform = "android-arm64",
        },
        { name = "Linux", id = "linux", isSupported = true, targetPlatform = "linux-riscv64" },
      }))

      assert.equal("emulator-5554", device.id)
    end)

    it("should skip devices whose platform directory is missing from the project", function()
      local project_root = vim.fn.tempname()
      vim.fn.mkdir(vim.fs.joinpath(project_root, "macos"), "p")

      local device = devices.resolve_default_device(
        machine_output({
          { name = "iPhone 16", id = "sim-id", isSupported = true, targetPlatform = "ios" },
          { name = "macOS", id = "macos", isSupported = true, targetPlatform = "darwin" },
        }),
        project_root
      )
      vim.fn.delete(project_root, "rf")

      assert.equal("macos", device.id)
    end)

    it("should skip notices printed before the JSON output", function()
      local output = machine_output({
        { name = "macOS", id = "macos", isSupported = true, targetPlatform = "darwin" },
      })
      table.insert(output, 1, "Waiting for another flutter command to release the startup lock...")

      assert.equal("macos", devices.resolve_default_device(output).id)
    end)

    it("should return nil for no devices or invalid output", function()
      assert.is_nil(devices.resolve_default_device(machine_output({})))
      assert.is_nil(devices.resolve_default_device({ "not json" }))
    end)
  end)
end)
