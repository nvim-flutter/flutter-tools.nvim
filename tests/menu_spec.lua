describe("menu.select_command", function()
  local menu
  local original_select
  local notifications
  local shown

  before_each(function()
    original_select = vim.ui.select
    notifications = {}
    shown = nil
    package.loaded["flutter-tools.menu"] = nil
    package.loaded["flutter-tools.ui"] = {
      ERROR = vim.log.levels.ERROR,
      notify = function(msg, level) table.insert(notifications, { msg = msg, level = level }) end,
    }
    vim.ui.select = function(items, opts, on_choice)
      shown = { items = items, opts = opts, on_choice = on_choice }
    end
    menu = require("flutter-tools.menu")
  end)

  after_each(function()
    vim.ui.select = original_select
    package.loaded["flutter-tools.menu"] = nil
    package.loaded["flutter-tools.ui"] = nil
  end)

  local function find_item(label)
    for _, item in ipairs(shown.items) do
      if item.label == label then return item end
    end
  end

  it("lists the commands through vim.ui.select with their hints", function()
    menu.select_command()

    local run = find_item("Run")
    assert.is_not_nil(run)
    assert.equal("flutter-tools", shown.opts.kind)
    assert.truthy(shown.opts.format_item(run):match("^Run +• Start a flutter project$"))
  end)

  it("aligns the hints in one column", function()
    menu.select_command()

    local columns = {}
    for _, item in ipairs(shown.items) do
      local column = shown.opts.format_item(item):find(" • ", 1, true)
      if column then columns[column] = true end
    end
    assert.equal(1, vim.tbl_count(columns))
  end)

  it("runs the chosen command", function()
    menu.select_command()
    local ran = false
    shown.on_choice({ label = "Test", command = function() ran = true end })
    assert.is_true(ran)
  end)

  it("reports a failing command instead of raising", function()
    menu.select_command()
    shown.on_choice({ label = "Test", command = function() error("boom") end })
    assert.equal(1, #notifications)
    assert.equal(vim.log.levels.ERROR, notifications[1].level)
    assert.truthy(notifications[1].msg:find("boom"))
  end)

  it("does nothing when the selection is cancelled", function()
    menu.select_command()
    shown.on_choice(nil)
    assert.equal(0, #notifications)
  end)
end)

describe("menu.select_fvm", function()
  local menu
  local original_select
  local used
  local shown

  before_each(function()
    original_select = vim.ui.select
    used = nil
    shown = nil
    package.loaded["flutter-tools.menu"] = nil
    package.loaded["flutter-tools.commands"] = {
      fvm_list = function(callback)
        callback({
          { name = "3.24.0", dart_sdk_version = "3.5.0" },
          { name = "stable" },
        })
      end,
      fvm_use = function(name) used = name end,
    }
    vim.ui.select = function(items, opts, on_choice)
      shown = { items = items, opts = opts, on_choice = on_choice }
    end
    menu = require("flutter-tools.menu")
  end)

  after_each(function()
    vim.ui.select = original_select
    package.loaded["flutter-tools.menu"] = nil
    package.loaded["flutter-tools.commands"] = nil
  end)

  it("lists the fvm SDKs with their Dart version", function()
    menu.select_fvm()

    assert.equal(2, #shown.items)
    assert.equal("3.24.0 • (Dart SDK 3.5.0)", shown.opts.format_item(shown.items[1]))
    assert.equal("stable", shown.opts.format_item(shown.items[2]))
  end)

  it("switches to the chosen SDK", function()
    menu.select_fvm()
    shown.on_choice(shown.items[1])
    assert.equal("3.24.0", used)
  end)
end)
