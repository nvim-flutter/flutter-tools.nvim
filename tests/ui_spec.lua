describe("ui.progress", function()
  local ui
  local original_timing
  local events
  local autocmd

  before_each(function()
    ui = require("flutter-tools.ui")
    original_timing = ui.progress_timing
    events = {}
    autocmd = vim.api.nvim_create_autocmd("Progress", {
      callback = function(ev) table.insert(events, { ev.data.status, ev.data.percent }) end,
    })
  end)

  after_each(function()
    ui.progress_timing = original_timing
    vim.api.nvim_del_autocmd(autocmd)
  end)

  it("resends a running progress so terminals keep the bar", function()
    ui.progress_timing = { keepalive_ms = 10, stall_ms = 60000 }
    local progress = ui.progress("Test")

    progress:report("Working", "running", { percent = 40 })
    vim.wait(100, function() return #events >= 3 end)
    progress:report("Done", "success")
    local count = #events
    vim.wait(50)

    assert.is_true(count >= 4)
    assert.are.same({ "running", 40 }, events[2])
    assert.are.same({ "success" }, events[count])
    assert.are.equal(count, #events)
  end)

  it("stops resending a progress that has not been updated for too long", function()
    ui.progress_timing = { keepalive_ms = 10, stall_ms = 0 }
    local progress = ui.progress("Test")

    progress:report("Working", "running")
    vim.wait(50)

    assert.are.same({ { "running" } }, events)
    progress:report("Done", "success")
  end)
end)
