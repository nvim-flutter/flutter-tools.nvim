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

  describe("emulator launch - ", function()
    local devices
    local config
    local jobs
    local modules = {
      "flutter-tools.devices",
      "flutter-tools.config",
      "flutter-tools.executable",
      "plenary.job",
    }
    local paths = { flutter_bin = "/sdk/bin/flutter" }
    local emulator = { id = "Pixel_8", name = "Pixel 8", system = "android", type = 1 }

    before_each(function()
      jobs = {}
      for _, name in ipairs(modules) do
        package.loaded[name] = nil
      end
      package.loaded["plenary.job"] = {
        new = function(_, opts)
          local job = { opts = opts, started = false }
          function job:after_success() end
          function job:after_failure() end
          function job:start() self.started = true end
          table.insert(jobs, job)
          return job
        end,
      }
      package.loaded["flutter-tools.executable"] = {
        get = function(callback) callback(paths) end,
      }
      config = require("flutter-tools.config")
      devices = require("flutter-tools.devices")
    end)

    after_each(function()
      for _, name in ipairs(modules) do
        package.loaded[name] = nil
      end
    end)

    it("should launch through flutter by default", function()
      devices.launch_emulator(vim.tbl_extend("force", emulator, { cold_boot = true }))

      assert.equal(1, #jobs)
      assert.equal("/sdk/bin/flutter", jobs[1].opts.command)
      assert.same({ "emulator", "--launch", "Pixel_8", "--cold" }, jobs[1].opts.args)
      assert.is_true(jobs[1].started)
    end)

    it("should use the command returned by a custom launcher", function()
      local received
      config.set({
        emulators = {
          launcher = function(e, p)
            received = { emulator = e, paths = p }
            return { command = "emulator", args = { "@" .. e.id, "-gpu", "host" } }
          end,
        },
      })

      devices.launch_emulator(emulator)

      assert.equal(emulator, received.emulator)
      assert.equal(paths, received.paths)
      assert.equal("emulator", jobs[1].opts.command)
      assert.same({ "@Pixel_8", "-gpu", "host" }, jobs[1].opts.args)
      assert.is_true(jobs[1].started)
    end)

    it("should fall back to flutter when the launcher returns nil", function()
      config.set({ emulators = { launcher = function() return nil end } })

      devices.launch_emulator(emulator)

      assert.equal("/sdk/bin/flutter", jobs[1].opts.command)
      assert.same({ "emulator", "--launch", "Pixel_8" }, jobs[1].opts.args)
    end)
  end)
end)
