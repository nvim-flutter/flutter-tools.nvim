describe("user commands", function()
  local ui = require("flutter-tools.ui")
  local original_notify = ui.notify
  local notifications

  before_each(function()
    notifications = {}
    ui.notify = function(msg) table.insert(notifications, msg) end
    require("flutter-tools").setup_project({})
  end)

  after_each(function() ui.notify = original_notify end)

  for _, name in ipairs({
    "FlutterDetach",
    "FlutterReload",
    "FlutterRestart",
    "FlutterQuit",
    "FlutterVisualDebug",
    "FlutterChangeTargetPlatform",
    "FlutterToggleBrightness",
    "FlutterOpenDevTools",
    "FlutterInspectWidget",
  }) do
    it(name .. " says that Flutter is not running", function()
      vim.cmd(name)
      assert.are.same({ "Sorry! Flutter is not running" }, notifications)
    end)
  end
end)
