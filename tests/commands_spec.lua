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

  it("should add multiple dart_defines", function()
    local args = commands.__get_run_args(
      {},
      { flavor = "Production", dart_define = { ENV = "prod", KEY = "VALUE" } }
    )
    assert.are.same(
      { "run", "--flavor", "Production", "--dart-define", "KEY=VALUE", "--dart-define", "ENV=prod" },
      args
    )
  end)
end)