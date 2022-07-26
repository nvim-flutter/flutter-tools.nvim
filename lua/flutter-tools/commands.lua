local Job = require("plenary.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local config = require("flutter-tools.config")
local executable = require("flutter-tools.executable")
local dev_tools = require("flutter-tools.dev_tools")
local lsp = require("flutter-tools.lsp")
local job_runner = require("flutter-tools.runners.job_runner")
local debugger_runner = require("flutter-tools.runners.debugger_runner")
local dev_log = require("flutter-tools.log")
local dap_ok, dap = pcall(require, "dap")

local M = {}

---@type table?
local current_device = nil

---@class FlutterRunner
---@field is_running fun():boolean
---@field run fun(runner: FlutterRunner, paths:table, args:table, cwd:string, on_run_data:fun(is_err:boolean, data:string), on_run_exit:fun(data:string[]))
---@field cleanup fun()
---@field send fun(runner: FlutterRunner, cmd:string, quiet: boolean?)

---@type FlutterRunner?
local runner = nil

function M.use_debugger_runner()
  if not config.get("debugger").run_via_dap then return false end
  if dap_ok then return true end
  ui.notify(
    { "debugger runner was request but nvim-dap is not installed!", dap },
    { level = ui.ERROR }
  )
  return false
end

function M.current_device()
  return current_device
end

function M.is_running()
  return runner ~= nil and runner:is_running()
end

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
  local dev_log_conf = config.get("dev_log")
  if is_err then ui.notify({ data }, { level = ui.ERROR, timeout = 5000, source = "process" }) end
  dev_log.log(data, dev_log_conf)
end

local function shutdown()
  if runner ~= nil then runner:cleanup() end
  runner = nil
  current_device = nil
  dev_tools.on_flutter_shutdown()
end

---Handle a finished flutter run command
---@param result string[]
local function on_run_exit(result, cli_args)
  local matched_error, msg = has_recoverable_error(result)
  if matched_error then
    local lines, win_devices, highlights = devices.extract_device_props(result)
    ui.popup_create({
      title = "Flutter run (" .. msg .. ") ",
      lines = lines,
      highlights = highlights,
      on_create = function(buf, _)
        vim.b.devices = win_devices
        utils.map("n", "<CR>", function()
          devices.select_device(cli_args)
        end, { buffer = buf })
      end,
    })
  end
  shutdown()
end

--- Take arguments from the commandline and pass
--- them to the run command
---@param args string
function M.run_command(args)
  args = args and args ~= "" and vim.split(args, " ") or nil
  M.run({ args = args })
end

local function check_if_web(args)
  for _, arg in ipairs(args) do
    local formatted = arg:lower()
    if formatted:match("chrome") or formatted:match("web") then return true end
  end
  return false
end

---Run the flutter application
---@param opts table
function M.run(opts)
  if M.is_running() then return ui.notify({ "Flutter is already running!" }) end
  opts = opts or {}
  local device = opts.device
  local cmd_args = opts.args
  local cli_args = opts.cli_args
  executable.get(function(paths)
    local args = cli_args or {}
    if not cli_args then
      if not M.use_debugger_runner() then vim.list_extend(args, { "run" }) end
      if not cmd_args and device and device.id then vim.list_extend(args, { "-d", device.id }) end

      if cmd_args then vim.list_extend(args, cmd_args) end

      local dev_url = dev_tools.get_url()
      if dev_url then vim.list_extend(args, { "--devtools-server-address", dev_url }) end
    end
    -- NOTE: debugging does not currently work with flutter web
    local is_web = check_if_web(args)
    if not vim.tbl_contains(args, "run") and is_web then table.insert(args, 1, "run") end
    ui.notify({ "Starting flutter project..." })
    runner = (M.use_debugger_runner() and not is_web) and debugger_runner or job_runner
    runner:run(paths, args, lsp.get_lsp_root_dir(), on_run_data, on_run_exit)
  end)
end

---@param cmd string
---@param quiet boolean?
---@param on_send function|nil
local function send(cmd, quiet, on_send)
  if M.is_running() and runner then
    runner:send(cmd, quiet)
    if on_send then on_send() end
  elseif not quiet then
    ui.notify({ "Sorry! Flutter is not running" })
  end
end

---@param quiet boolean?
function M.reload(quiet)
  send("reload", quiet)
end

---@param quiet boolean?
function M.restart(quiet)
  send("restart", quiet, function()
    if not quiet then ui.notify({ "Restarting..." }, { timeout = 1500 }) end
  end)
end

---@param quiet boolean?
function M.quit(quiet)
  send("quit", quiet, function()
    if not quiet then
      ui.notify({ "Closing flutter application..." }, { timeout = 1500 })
      shutdown()
    end
  end)
end

---@param quiet boolean?
function M.visual_debug(quiet)
  send("visual_debug", quiet)
end

---@param quiet boolean?
function M.detach(quiet)
  send("detach", quiet)
end

function M.copy_profiler_url()
  if not M.is_running() then
    ui.notify({ "You must run the app first!" })
    return
  end

  local url, is_running = dev_tools.get_profiler_url()

  if url then
    vim.cmd("let @+='" .. url .. "'")
    ui.notify({ "Profiler url copied to clipboard!" })
  elseif is_running then
    ui.notify({ "Wait while the app starts", "please try again later" })
  else
    ui.notify({ "You must start the DevTools server first!" })
  end
end

---@param quiet boolean?
function M.open_dev_tools(quiet)
  send("open_dev_tools", quiet)
end

---@param quiet boolean
function M.generate(quiet)
  send("generate", quiet)
end

---@param quiet boolean
function M.widget_inspector(quiet)
  send("inspect", quiet)
end

---@param quiet boolean
function M.construction_lines(quiet)
  send("construction_lines", quiet)
end

-----------------------------------------------------------------------------//
-- Pub commands
-----------------------------------------------------------------------------//
---Print result of running pub get
---@param result string[]
local function on_pub_get(result, err)
  local timeout = err and 10000 or nil
  ui.notify(result, { timeout = timeout })
end

---@type Job?
local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    executable.flutter(function(cmd)
      pub_get_job = Job:new({
        command = cmd,
        args = { "pub", "get" },
        cwd = lsp.get_lsp_root_dir(),
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
      pub_upgrade_job = Job:new({ command = cmd, args = args, cwd = lsp.get_lsp_root_dir() })
      pub_upgrade_job:after_success(vim.schedule_wrap(function(j)
        ui.notify(j:result(), { timeout = notify_timeout })
        pub_upgrade_job = nil
      end))
      pub_upgrade_job:after_failure(vim.schedule_wrap(function(j)
        ui.notify(j:stderr_result(), { timeout = notify_timeout })
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
    -- Example output:
    --
    -- Cache Directory:  /Users/rjm/fvm/versions
    --
    -- master (active)
    -- beta
    -- stable (global)
    fvm_list_job = Job:new({ command = "fvm", args = { "list" } })

    fvm_list_job:after_success(vim.schedule_wrap(function(j)
      local out = j:result()
      local sdks_out = { unpack(out, 3, #out) }

      local sdks = {}
      for _, sdk_out in pairs(sdks_out) do
        -- matches: "<name> (<status>)"
        local name, status = sdk_out:match("(.*)%s%((%w+)%)")
        name = name or sdk_out
        table.insert(sdks, { name = name, status = status })
      end

      callback(sdks)
      fvm_list_job = nil
    end))

    fvm_list_job:after_failure(vim.schedule_wrap(function(j)
      ui.notify(j:stderr_result(), { level = ui.ERROR })
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
      ui.notify(j:result())
      shutdown()
      executable.reset_paths()
      require("flutter-tools.lsp").restart()

      fvm_use_job = nil
    end))

    fvm_use_job:after_failure(vim.schedule_wrap(function(j)
      ui.notify(j:result(), { timeout = 10000 }) -- FVM doesn't output to stderr, nice
      fvm_use_job = nil
    end))

    fvm_use_job:start()
  end
end

return M
