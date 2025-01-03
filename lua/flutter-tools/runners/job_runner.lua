local Job = require("plenary.job")
local ui = require("flutter-tools.ui")
local dev_tools = require("flutter-tools.dev_tools")
local utils = require("flutter-tools.utils") ---@module "flutter-tools.utils"

---@type flutter.Runner
local JobRunner = {}

---@type Job
local run_job = nil

local command_keys = {
  restart = "R",
  reload = "r",
  quit = "q",
  visual_debug = "p",
  detach = "d",
  inspect_widget = "i",
  paint_baselines = "p",
  open_dev_tools = "v",
  generate = "g",
}

function JobRunner:is_running() return run_job ~= nil end

function JobRunner:run(
  paths,
  args,
  cwd,
  on_run_data,
  on_run_exit,
  is_flutter_project,
  project_config
)
  local command, command_args
  if is_flutter_project then
    command = paths.flutter_bin
    command_args = args
  else
    command = paths.dart_bin
    command_args = { "run" } ---@type string[]
    if project_config and project_config.target then
      table.insert(command_args, project_config.target)
    end
  end
  run_job = Job:new({
    command = command,
    args = command_args,
    cwd = cwd,
    on_start = function() utils.emit_event(utils.events.APP_STARTED) end,
    on_stdout = vim.schedule_wrap(function(_, data, _)
      on_run_data(false, data)
      dev_tools.handle_log(data)
    end),
    on_stderr = vim.schedule_wrap(function(_, data, _) on_run_data(true, data) end),
    on_exit = vim.schedule_wrap(function(j, _) on_run_exit(j:result(), args, project_config) end),
  })
  run_job:start()
end

function JobRunner:send(cmd, quiet)
  local key = command_keys[cmd]
  if key ~= nil then
    run_job:send(key)
  elseif not quiet then
    ui.notify("Command " .. cmd .. " is not yet implemented for CLI runner", ui.ERROR)
  end
end

function JobRunner:cleanup() run_job = nil end

function JobRunner:attach(paths, args, cwd, on_run_data, on_run_exit)
  local command = paths.flutter_bin
  local command_args = args

  run_job = Job:new({
    command = command,
    args = command_args,
    cwd = cwd,
    on_start = function() utils.emit_event(utils.events.APP_STARTED) end,
    on_stdout = vim.schedule_wrap(function(_, data, _)
      on_run_data(false, data)
      dev_tools.handle_log(data)
    end),
    on_stderr = vim.schedule_wrap(function(_, data, _) on_run_data(true, data) end),
    on_exit = vim.schedule_wrap(function(j, _) on_run_exit(j:result(), args) end),
  })
  run_job:start()
end

return JobRunner
