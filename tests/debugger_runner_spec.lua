local paths = {
  flutter_bin = "/sdk/flutter/bin/flutter",
  flutter_sdk = "/sdk/flutter",
  dart_bin = "/sdk/flutter/bin/dart",
  dart_sdk = "/sdk/flutter/bin/cache/dart-sdk",
}

describe("debugger runner", function()
  local dap, runner

  before_each(function()
    dap = require("dap")
    runner = require("flutter-tools.runners.debugger_runner")
  end)

  after_each(function()
    dap.adapters.dart = nil
    dap.configurations.dart = nil
    dap.listeners.after["event_output"]["flutter-tools"] = nil
    runner.on_untracked_session(function() end)
    package.loaded["flutter-tools.runners.debugger_runner"] = nil
  end)

  it("registers the adapter and default configurations", function()
    runner.register_defaults(paths, true, nil, "/project")

    assert.are.same({
      type = "executable",
      command = paths.flutter_bin,
      args = { "debug-adapter" },
    }, dap.adapters.dart)
    assert.are.same(
      { "Launch flutter", "Connect flutter" },
      vim.tbl_map(function(c) return c.name end, dap.configurations.dart)
    )
    assert.are.equal("/project", dap.configurations.dart[1].cwd)
  end)

  it("keeps an adapter and configurations the user defined", function()
    local adapter = { type = "executable", command = "custom" }
    local configurations = { { type = "dart", request = "launch", name = "Mine" } }
    dap.adapters.dart = adapter
    dap.configurations.dart = configurations

    runner.register_defaults(paths, true, nil, "/project")

    assert.are.equal(adapter, dap.adapters.dart)
    assert.are.equal(configurations, dap.configurations.dart)
  end)

  it("routes output of sessions started outside flutter-tools", function()
    local lines = {}
    runner.on_untracked_session(function()
      return {
        on_run_data = function(is_err, line) table.insert(lines, { is_err, line }) end,
        on_run_exit = function() end,
      }
    end)

    dap.listeners.on_session["flutter-tools"](nil, { id = 1, config = { type = "dart" } })
    dap.listeners.after["event_output"]["flutter-tools"](nil, {
      category = "stderr",
      output = "first\nsecond",
    })

    assert.are.same({ { true, "first" }, { true, "second" } }, lines)
  end)

  it("ignores sessions of other adapters", function()
    local called = false
    runner.on_untracked_session(function() called = true end)

    dap.listeners.on_session["flutter-tools"](nil, { id = 2, config = { type = "python" } })

    assert.is_false(called)
  end)
end)
