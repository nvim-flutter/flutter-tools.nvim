describe("config", function()
  local config
  local ui
  local notifications
  local original_has

  before_each(function()
    notifications = {}
    original_has = vim.fn.has

    package.loaded["flutter-tools.config"] = nil
    package.loaded["flutter-tools.ui"] = nil

    ui = require("flutter-tools.ui")
    ui.notify = function(msg, level) table.insert(notifications, { msg = msg, level = level }) end

    config = require("flutter-tools.config")
  end)

  after_each(function()
    vim.fn.has = original_has
    package.loaded["flutter-tools.config"] = nil
    package.loaded["flutter-tools.ui"] = nil
  end)

  it("warns when lsp.color is configured on Neovim 0.12+", function()
    vim.fn.has = function(feature)
      if feature == "nvim-0.12" then return 1 end
      return original_has(feature)
    end

    config.set({
      lsp = {
        color = {
          enabled = true,
        },
      },
    })

    vim.wait(1200)

    assert.equal(1, #notifications)
    assert.equal(
      "lsp.color is deprecated: plugin-managed document colors are deprecated and will be removed when flutter-tools.nvim requires Neovim 0.12+. On Neovim 0.12+, use vim.lsp.document_color.enable() instead",
      notifications[1].msg
    )
    assert.equal(ui.WARN, notifications[1].level)
  end)

  it("does not warn when lsp.color is configured before Neovim 0.12", function()
    vim.fn.has = function(feature)
      if feature == "nvim-0.12" then return 0 end
      return original_has(feature)
    end

    config.set({
      lsp = {
        color = {
          enabled = true,
        },
      },
    })

    vim.wait(1200)

    assert.same({}, notifications)
  end)

  it("does not warn when lsp.color is omitted", function()
    config.set({
      lsp = {
        debug = config.debug_levels.DEBUG,
      },
    })

    vim.wait(1200)

    assert.same({}, notifications)
  end)
end)
