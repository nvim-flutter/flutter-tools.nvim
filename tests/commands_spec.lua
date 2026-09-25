local utils = require("flutter-tools.utils")

describe("commands", function()
  local commands
  before_each(function() commands = require("flutter-tools.commands") end)
  after_each(function()
    commands = nil
    package.loaded["flutter-tools.commands"] = nil
  end)
  it(
    "should add project config options correctly",
    function()
      assert.are.same(
        { "run", "--flavor", "Production" },
        commands.__get_run_args({}, { flavor = "Production" })
      )
    end
  )

  it(
    "should add 'dart_defines' options correctly",
    function()
      assert.are.same(
        { "run", "--flavor", "Production", "--dart-define", "ENV=prod" },
        commands.__get_run_args({}, { flavor = "Production", dart_define = { ENV = "prod" } })
      )
    end
  )

  it(
    "should add 'target' config option correctly",
    function()
      assert.are.same(
        { "run", "--target", "lib/main_dev.dart" },
        commands.__get_run_args({}, { target = "lib/main_dev.dart" })
      )
    end
  )

  it(
    "should add 'dart-define-from-file' config option correctly",
    function()
      assert.are.same(
        { "run", "--dart-define-from-file", "config.json" },
        commands.__get_run_args({}, { dart_define_from_file = "config.json" })
      )
    end
  )

  it("should add multiple dart_defines", function()
    local args = commands.__get_run_args({}, {
      flavor = "Production",
      dart_define = { ENV = "prod", KEY = "VALUE" },
    })
    local result = utils.fold(function(acc, v)
      acc[v] = acc[v] and acc[v] + 1 or 1
      return acc
    end, args, {})

    assert.are.same(result, {
      ["run"] = 1,
      ["--flavor"] = 1,
      ["Production"] = 1,
      ["--dart-define"] = 2,
      ["ENV=prod"] = 1,
      ["KEY=VALUE"] = 1,
    })
  end)

  it(
    "should add '--profile' config option correctly",
    function()
      assert.are.same(
        { "run", "--profile" },
        commands.__get_run_args({}, { flutter_mode = "profile" })
      )
    end
  )

  it(
    "should add '--release' config option correctly",
    function()
      assert.are.same(
        { "run", "--release" },
        commands.__get_run_args({}, { flutter_mode = "release" })
      )
    end
  )

  it("should pick up the device name from the run output", function()
    commands.__update_device_from_output(
      "Launching lib/main.dart on iPhone 16 Pro in debug mode..."
    )

    assert.equal("iPhone 16 Pro", commands.current_device().name)
  end)

  it("should keep the device id when the name is parsed from the run output", function()
    commands.__set_current_device({ id = "macos" })
    commands.__update_device_from_output("Launching lib/main.dart on macOS in debug mode...")

    local device = commands.current_device()
    assert.equal("macos", device.id)
    assert.equal("macOS", device.name)
  end)

  it("should ignore unrelated output lines", function()
    commands.__update_device_from_output('Running "flutter pub get" in example...')

    assert.is_nil(commands.current_device())
  end)
end)
