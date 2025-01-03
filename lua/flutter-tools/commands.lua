local lazy = require("flutter-tools.lazy")
local Job = require("plenary.job") ---@module "plenary.job"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local devices = lazy.require("flutter-tools.devices") ---@module "flutter-tools.devices"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local executable = lazy.require("flutter-tools.executable") ---@module "flutter-tools.executable"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module   "flutter-tools.dev_tools"
local lsp = lazy.require("flutter-tools.lsp") ---@module "flutter-tools.lsp"
local job_runner = lazy.require("flutter-tools.runners.job_runner") ---@module "flutter-tools.runners.job_runner"
local debugger_runner = lazy.require("flutter-tools.runners.debugger_runner") ---@module "flutter-tools.runners.debugger_runner"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local dev_log = lazy.require("flutter-tools.log") ---@module "flutter-tools.log"
local parser = lazy.require("flutter-tools.utils.yaml_parser")

local M = {}

---@alias RunOpts {cli_args: string[]?, args: string[]?, device: Device?, force_debug: boolean?}
---@alias AttachOpts {cli_args: string[]?, args: string[]?, device: Device?}

---@type table?
local current_device = nil

---@class flutter.Runner
---@field is_running fun(runner: flutter.Runner):boolean
---@field run fun(runner: flutter.Runner, paths:table, args:table, cwd:string, on_run_data:fun(is_err:boolean, data:string), on_run_exit:fun(data:string[], args: table, project_conf: flutter.ProjectConfig?,launch_config: dap.Configuration?),  is_flutter_project: boolean, project_conf: flutter.ProjectConfig?, launch_config: dap.Configuration?)
---@field cleanup fun(funner: flutter.Runner)
---@field send fun(runner: flutter.Runner, cmd:string, quiet: boolean?)
---@field attach fun(runner: flutter.Runner, paths:table, args:table, cwd:string, on_run_data:fun(is_err:boolean, data:string), on_run_exit:fun(data:string[], args: table, project_conf: flutter.ProjectConfig?,launch_config: dap.Configuration?))

---@type flutter.Runner?
local runner = nil

local function use_debugger_runner(force_debug)
  if force_debug or config.debugger.enabled then
    local dap_ok, _ = pcall(require, "dap")
    if dap_ok then return true end
    ui.notify("debugger runner was request but nvim-dap is not installed!", ui.ERROR)
    return false
  end
  return false
end

function M.current_device() return current_device end

function M.is_running() return runner ~= nil and runner:is_running() end

local function match_error_string(line)
  if not line then return false end
  -- match the error string if no devices are setup
  if line:match("No supported devices connected") ~= nil then
    -- match the error string returned if multiple devices are matched
    return true, "Choose a device"
  elseif line:match("More than one device connected") ~= nil then
    return true, "Choose a device"
  end
end

---@param lines string[]
---@return boolean, string?
local function has_recoverable_error(lines)
  for _, line in pairs(lines) do
    local match, msg = match_error_string(line)
    if match then return match, msg end
  end
  return false, nil
end

---Handle output from flutter run command
---@param is_err boolean if this is stdout or stderr
local function on_run_data(is_err, data)
  if is_err and config.dev_log.notify_errors then ui.notify(data, ui.ERROR, { timeout = 5000 }) end
  dev_log.log(data)
end

local function shutdown()
  if runner then runner:cleanup() end
  runner = nil
  current_device = nil
  utils.emit_event(utils.events.PROJECT_CONFIG_CHANGED)
  dev_tools.on_flutter_shutdown()
end

---Handle a finished flutter run command
---@param result string[]
---@param cli_args string[]
---@param project_config flutter.ProjectConfig?
---@param launch_config dap.Configuration?
local function on_run_exit(result, cli_args, project_config, launch_config)
  local matched_error, msg = has_recoverable_error(result)
  if matched_error then
    local lines = devices.to_selection_entries(result)
    ui.select({
      title = ("Flutter run (%s)"):format(msg),
      lines = lines,
      on_select = function(device)
        vim.list_extend(cli_args, { "-d", device.id })
        if launch_config then vim.list_extend(launch_config.args, { "-d", device.id }) end
        M.run({ cli_args = cli_args }, project_config, launch_config)
      end,
    })
  end
  shutdown()
end

--- Take arguments from the commandline and pass
--- them to the run command
---@param args string
---@param force_debug boolean true if the command is a debug command
function M.run_command(args, force_debug)
  args = args and args ~= "" and vim.split(args, " ") or nil
  M.run({ args = args, force_debug = force_debug })
end

---@param callback fun(project_config: flutter.ProjectConfig?)
local function select_project_config(callback)
  local project_config = config.project --[=[@as flutter.ProjectConfig[]]=]
  if #project_config <= 1 then
    utils.emit_event(utils.events.PROJECT_CONFIG_CHANGED, { data = project_config[1] })
    return callback(project_config[1])
  end
  vim.ui.select(project_config, {
    prompt = "Select a project configuration",
    format_item = function(item)
      if item.name then return item.name end
      return vim.inspect(item)
    end,
  }, function(selected)
    if selected then
      utils.emit_event(utils.events.PROJECT_CONFIG_CHANGED, { data = selected })
      callback(selected)
    end
  end)
end

---@param opts RunOpts
---@param conf flutter.ProjectConfig?
---@return string[]
local function get_run_args(opts, conf)
  local args = {}
  local cmd_args = opts.args
  local device = conf and conf.device or (opts.device and opts.device.id)
  local flavor = conf and conf.flavor
  local target = conf and conf.target
  local dart_defines = conf and conf.dart_define
  local dart_define_from_file = conf and conf.dart_define_from_file
  local flutter_mode = conf and conf.flutter_mode
  local web_port = conf and conf.web_port
  local dev_url = dev_tools.get_url()
  local additional_args = conf and conf.additional_args

  if not use_debugger_runner(opts.force_debug) then vim.list_extend(args, { "run" }) end
  if not cmd_args and device then vim.list_extend(args, { "-d", device }) end
  if web_port then vim.list_extend(args, { "--web-port", web_port }) end
  if cmd_args then vim.list_extend(args, cmd_args) end
  if flavor then vim.list_extend(args, { "--flavor", flavor }) end
  if target then vim.list_extend(args, { "--target", target }) end
  if dart_define_from_file then
    vim.list_extend(args, { "--dart-define-from-file", dart_define_from_file })
  end
  if dart_defines then
    for key, value in pairs(dart_defines) do
      vim.list_extend(args, { "--dart-define", ("%s=%s"):format(key, value) })
    end
  end
  if flutter_mode then
    if flutter_mode == "profile" then
      vim.list_extend(args, { "--profile" })
    elseif flutter_mode == "release" then
      vim.list_extend(args, { "--release" })
    end -- else default to debug
  end
  if dev_url then vim.list_extend(args, { "--devtools-server-address", dev_url }) end
  if additional_args then vim.list_extend(args, additional_args) end
  return args
end

--- @param args string[]
--- @return Device?
local function get_device_from_args(args)
  for i = 1, #args - 1 do
    if args[i] == "-d" then return { id = args[i + 1] } end
  end
end

local function get_absolute_path(input_path)
  -- Check if the provided path is an absolute path
  if
    vim.fn.isdirectory(input_path) == 1
    and not input_path:match("^/")
    and not input_path:match("^%a:[/\\]")
  then
    -- It's a relative path, so expand it to an absolute path
    local absolute_path = vim.fn.fnamemodify(input_path, ":p")
    return absolute_path
  else
    -- It's already an absolute path
    return input_path
  end
end

---@param project_conf flutter.ProjectConfig?
local function get_cwd(project_conf)
  if project_conf and project_conf.cwd then
    local resolved_path = get_absolute_path(project_conf.cwd)
    if not vim.loop.fs_stat(resolved_path) then
      return ui.notify("Provided cwd does not exist: " .. resolved_path, ui.ERROR)
    end
    return resolved_path
  end
  return lsp.get_lsp_root_dir()
end

--@return table?
local function parse_yaml(str)
  local ok, yaml = pcall(parser.parse, str)
  if not ok then return nil end
  return yaml
end

---@param cwd string
local function has_flutter_dependency_in_pubspec(cwd)
  -- As this plugin is tailored for flutter projects,
  -- we assume that the project is a flutter project.
  local default_has_flutter_dependency = true
  local pubspec_path = vim.fn.glob(path.join(cwd, "pubspec.yaml"))
  if pubspec_path == "" then return default_has_flutter_dependency end
  local pubspec_content = vim.fn.readfile(pubspec_path)
  local joined_content = table.concat(pubspec_content, "\n")
  local pubspec = parse_yaml(joined_content)
  if not pubspec then return default_has_flutter_dependency end
  --https://github.com/Dart-Code/Dart-Code/blob/43914cd2709d77668e19a4edf3500f996d5c307b/src/shared/utils/fs.ts#L183
  return (
    pubspec.dependencies
    and (
      pubspec.dependencies.flutter
      or pubspec.dependencies.flutter_test
      or pubspec.dependencies.sky_engine
      or pubspec.dependencies.flutter_goldens
    )
  )
    or (
      pubspec.devDependencies
      and (
        pubspec.devDependencies.flutter
        or pubspec.devDependencies.flutter_test
        or pubspec.devDependencies.sky_engine
        or pubspec.devDependencies.flutter_goldens
      )
    )
end

---@param opts RunOpts
---@param project_conf flutter.ProjectConfig?
---@param launch_config dap.Configuration?
local function run(opts, project_conf, launch_config)
  opts = opts or {}
  executable.get(function(paths)
    local args = opts.cli_args or get_run_args(opts, project_conf)

    current_device = opts.device or get_device_from_args(args)
    if project_conf then
      if project_conf.pre_run_callback then
        local callback_args = {
          name = project_conf.name,
          target = project_conf.target,
          flavor = project_conf.flavor,
          device = project_conf.device,
        }
        project_conf.pre_run_callback(callback_args)
      end
    end
    local cwd = get_cwd(project_conf)
    -- To determinate if the project is a flutter project we need to check if the pubspec.yaml
    -- file has a flutter dependency in it. We need to get cwd first to pick correct pubspec.yaml file.
    local is_flutter_project = has_flutter_dependency_in_pubspec(cwd)
    if is_flutter_project then
      ui.notify("Starting flutter project...")
    else
      ui.notify("Starting dart project...")
    end
    runner = use_debugger_runner(opts.force_debug) and debugger_runner or job_runner
    runner:run(
      paths,
      args,
      cwd,
      on_run_data,
      on_run_exit,
      is_flutter_project,
      project_conf,
      launch_config
    )
  end)
end

---Run the flutter application
---@param opts RunOpts
---@param project_conf flutter.ProjectConfig?
---@param launch_config dap.Configuration?
function M.run(opts, project_conf, launch_config)
  if M.is_running() then return ui.notify("Flutter is already running!") end
  if project_conf then
    run(opts, project_conf, launch_config)
  else
    select_project_config(
      function(selected_project_conf) run(opts, selected_project_conf, launch_config) end
    )
  end
end

---@param opts AttachOpts
local function attach(opts)
  opts = opts or {}
  executable.get(function(paths)
    local args = opts.cli_args or {}
    if not use_debugger_runner() then vim.list_extend(args, { "attach" }) end

    local cwd = get_cwd()
    ui.notify("Attaching flutter project...")
    runner = use_debugger_runner() and debugger_runner or job_runner
    runner:attach(paths, args, cwd, on_run_data, on_run_exit)
  end)
end

--- Attach to a running app
---@param opts AttachOpts
function M.attach(opts)
  if M.is_running() then return ui.notify("Flutter is already running!") end
  attach(opts)
end

---@param cmd string
---@param quiet boolean?
---@param on_send function|nil
local function send(cmd, quiet, on_send)
  if M.is_running() and runner then
    runner:send(cmd, quiet)
    if on_send then on_send() end
  elseif not quiet then
    ui.notify("Sorry! Flutter is not running")
  end
end

---@param quiet boolean?
function M.reload(quiet) send("reload", quiet) end

---@param quiet boolean?
function M.restart(quiet)
  send("restart", quiet, function()
    if not quiet then ui.notify("Restarting...", nil, { timeout = 1500 }) end
  end)
end

---@param quiet boolean?
function M.quit(quiet)
  send("quit", quiet, function()
    if not quiet then
      ui.notify("Closing flutter application...", nil, { timeout = 1500 })
      shutdown()
    end
  end)
end

---@param quiet boolean?
function M.visual_debug(quiet) send("visual_debug", quiet) end

---@param quiet boolean?
function M.performance_overlay(quiet) send("performance_overlay", quiet) end

---@param quiet boolean?
function M.repaint_rainbow(quiet) send("repaint_rainbow", quiet) end

---@param quiet boolean?
function M.slow_animations(quiet) send("slow_animations", quiet) end

---@param quiet boolean?
function M.detach(quiet) send("detach", quiet) end

function M.copy_profiler_url()
  if not M.is_running() then
    ui.notify("You must run the app first!")
    return
  end

  local url, is_running = dev_tools.get_profiler_url()

  if url then
    vim.cmd("let @+='" .. url .. "'")
    ui.notify("Profiler url copied to clipboard!")
  elseif is_running then
    ui.notify("Wait while the app starts", "please try again later")
  else
    ui.notify("You must start the DevTools server first!")
  end
end

---@param quiet boolean?
function M.open_dev_tools(quiet) send("open_dev_tools", quiet) end

---@param quiet boolean
function M.generate(quiet) send("generate", quiet) end

---@param quiet boolean
function M.inspect_widget(quiet) send("inspect_widget", quiet) end

---@param quiet boolean
function M.paint_baselines(quiet) send("paint_baselines", quiet) end

-----------------------------------------------------------------------------//
-- Pub commands
-----------------------------------------------------------------------------//
---Print result of running pub get
---@param result string[]
local function on_pub_get(result, err)
  local timeout = err and 10000 or nil
  ui.notify(utils.join(result), nil, { timeout = timeout })
end

---@type Job?
local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    executable.flutter(function(cmd)
      pub_get_job = Job:new({
        command = cmd,
        args = { "pub", "get" },
        -- stylua: ignore
        cwd = lsp.get_lsp_root_dir() --[[@as string]],
      })
      pub_get_job:after_success(vim.schedule_wrap(function(j)
        on_pub_get(j:result())
        pub_get_job = nil
      end))
      pub_get_job:after_failure(vim.schedule_wrap(function(j)
        on_pub_get(j:stderr_result(), true)
        pub_get_job = nil
      end))
      pub_get_job:start()
    end)
  end
end

---@type Job?
local pub_upgrade_job = nil

--- Take arguments from the commandline and pass
--- them to the pub upgrade command
---@param args string
function M.pub_upgrade_command(args)
  args = args and args ~= "" and vim.split(args, " ") or nil
  M.pub_upgrade(args)
end

function M.pub_upgrade(cmd_args)
  if not pub_upgrade_job then
    executable.flutter(function(cmd)
      local notify_timeout = 10000
      local args = { "pub", "upgrade" }
      if cmd_args then vim.list_extend(args, cmd_args) end
      pub_upgrade_job = Job:new({
        command = cmd,
        args = args,
        -- stylua: ignore
        cwd = lsp.get_lsp_root_dir() --[[@as string]],
      })
      pub_upgrade_job:after_success(vim.schedule_wrap(function(j)
        ui.notify(utils.join(j:result()), nil, { timeout = notify_timeout })
        pub_upgrade_job = nil
      end))
      pub_upgrade_job:after_failure(vim.schedule_wrap(function(j)
        ui.notify(utils.join(j:stderr_result()), nil, { timeout = notify_timeout })
        pub_upgrade_job = nil
      end))
      pub_upgrade_job:start()
    end)
  end
end

-----------------------------------------------------------------------------//
-- FVM commands
-----------------------------------------------------------------------------//

---@type Job?
local fvm_list_job = nil

--- Returns table<{name: string, status: active|global|nil}>
function M.fvm_list(callback)
  if not fvm_list_job then
    fvm_list_job = Job:new({ command = "fvm", args = { "api", "list" } })

    fvm_list_job:after_success(vim.schedule_wrap(function(j)
      local out = j:result()
      local json_str = table.concat(out, "\n")
      -- Parse the JSON string
      local ok, parsed = pcall(vim.json.decode, json_str)
      if not ok then
        ui.notify("Failed to parse fvm list output", ui.ERROR)
        fvm_list_job = nil
        return
      end

      local sdks = {}
      for _, version in pairs(parsed.versions) do
        table.insert(sdks, {
          name = version.name,
          dart_sdk_version = version.dartSdkVersion,
        })
      end

      callback(sdks)
      fvm_list_job = nil
    end))

    fvm_list_job:after_failure(vim.schedule_wrap(function(j)
      ui.notify(utils.join(j:stderr_result()), ui.ERROR)
      fvm_list_job = nil
    end))

    fvm_list_job:start()
  end
end

---@type Job?
local fvm_use_job = nil

function M.fvm_use(sdk_name)
  if not fvm_use_job then
    fvm_use_job = Job:new({ command = "fvm", args = { "use", sdk_name } })

    fvm_use_job:after_success(vim.schedule_wrap(function(j)
      ui.notify(utils.join(j:result()))
      shutdown()
      executable.reset_paths()
      lsp.restart()

      fvm_use_job = nil
    end))

    fvm_use_job:after_failure(vim.schedule_wrap(function(j)
      ui.notify(utils.join(j:result()), nil, { timeout = 10000 }) -- FVM doesn't output to stderr, nice
      fvm_use_job = nil
    end))

    fvm_use_job:start()
  end
end

---@param args string[]
---@param project_conf flutter.ProjectConfig?
local function set_args_from_project_config(args, project_conf)
  local flavor = project_conf and project_conf.flavor
  local device = project_conf and project_conf.device
  if flavor then vim.list_extend(args, { "--flavor", flavor }) end
  if device then vim.list_extend(args, { "-d", device }) end
end

---@type Job?
local install_job = nil

function M.install()
  if not install_job then
    select_project_config(function(project_conf)
      local args = { "install" }
      set_args_from_project_config(args, project_conf)
      ui.notify("Installing the app...")
      executable.flutter(function(cmd)
        local notify_timeout = 10000
        install_job = Job:new({
          command = cmd,
          args = args,
          -- stylua: ignore
          cwd = lsp.get_lsp_root_dir() --[[@as string]],
        })
        install_job:after_success(vim.schedule_wrap(function(j)
          ui.notify(utils.join(j:result()), nil, { timeout = notify_timeout })
          install_job = nil
        end))
        install_job:after_failure(vim.schedule_wrap(function(j)
          ui.notify(utils.join(j:result()), nil, { timeout = notify_timeout })
          install_job = nil
        end))
        install_job:start()
      end)
    end)
  end
end

---@type Job?
local uninstall_job = nil

function M.uninstall()
  if not uninstall_job then
    select_project_config(function(project_conf)
      local args = { "install", "--uninstall-only" }
      set_args_from_project_config(args, project_conf)
      ui.notify("Uninstalling the app...")
      executable.flutter(function(cmd)
        local notify_timeout = 10000
        uninstall_job = Job:new({
          command = cmd,
          args = args,
          -- stylua: ignore
          cwd = lsp.get_lsp_root_dir() --[[@as string]],
        })
        uninstall_job:after_success(vim.schedule_wrap(function(j)
          ui.notify(utils.join(j:result()), nil, { timeout = notify_timeout })
          uninstall_job = nil
        end))
        uninstall_job:after_failure(vim.schedule_wrap(function(j)
          ui.notify(utils.join(j:result()), nil, { timeout = notify_timeout })
          uninstall_job = nil
        end))
        uninstall_job:start()
      end)
    end)
  end
end

if __TEST then
  M.__run = run
  M.__get_run_args = get_run_args
end

return M
