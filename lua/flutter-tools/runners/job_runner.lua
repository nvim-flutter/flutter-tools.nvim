local Job = require("plenary.job")
local ui = require("flutter-tools.ui")
local dev_tools = require("flutter-tools.dev_tools")

---@type FlutterRunner
local JobRunner = {}

---@type Job
local run_job = nil

local command_keys = {
  restart = "R",
  reload = "r",
  quit = "q",
  visual_debug = "p",
  detach = "d",
  inspect = "i",
  construction_lines = "p",
  open_dev_tools = "v",
  generate = "g",
}

function JobRunner:is_running()
  return run_job ~= nil
end

function JobRunner:run(paths, args, cwd, on_run_data, on_run_exit)
  run_job = Job:new({
    command = paths.flutter_bin,
    args = args,
    cwd = cwd,
    on_start = function()
      vim.cmd("doautocmd User FlutterToolsAppStarted")
    end,
    on_stdout = vim.schedule_wrap(function(_, data, _)
      on_run_data(false, data)
      dev_tools.handle_log(data)
    end),
    on_stderr = vim.schedule_wrap(function(_, data, _)
      on_run_data(true, data)
    end),
    on_exit = vim.schedule_wrap(function(j, _)
      on_run_exit(j:result(), args)
    end),
  })
  run_job:start()
end

function JobRunner:send(cmd, quiet)
  local key = command_keys[cmd]
  if key ~= nil then
    run_job:send(key)
  elseif not quiet then
    ui.notify(
      { "Command " .. cmd .. " is not yet implemented for CLI runner" },
      { level = ui.ERROR }
    )
  end
end

function JobRunner:cleanup()
  run_job = nil
end

return JobRunner
