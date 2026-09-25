local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local executable = lazy.require("flutter-tools.executable") ---@module "flutter-tools.executable"
local dtd = lazy.require("flutter-tools.dtd") ---@module "flutter-tools.dtd"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"

--- Runs `flutter widget-preview start`, mirroring Dart-Code's
--- src/extension/flutter/widget_preview_server.ts.
local M = {}

local api = vim.api

local ANALYSIS_TIMEOUT_MS = 120000
local OUTPUT_LINES_ON_FAILURE = 15

---@class flutter.WidgetPreviewState
---@field job vim.SystemObj?
---@field pid integer? process reported by the `widget_preview.initializing` event
---@field url string?
---@field started boolean
---@field cancelled boolean
---@field output string[] recent output, shown if the previewer fails
---@field dir string
---@field progress_id (integer|string)?

---@type flutter.WidgetPreviewState?
local state = nil

---@param color integer?
---@return string?
local function to_hex(color)
  if color then return ("#%06x"):format(color) end
end

---@param url string
---@return string
local function with_theme(url)
  local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
  local params = { "theme=" .. (vim.o.background == "light" and "light" or "dark") }
  for key, color in pairs({
    backgroundColor = to_hex(normal.bg),
    foregroundColor = to_hex(normal.fg),
  }) do
    params[#params + 1] = key .. "=" .. vim.uri_encode(color)
  end
  return url .. (url:find("?", 1, true) and "&" or "?") .. table.concat(params, "&")
end

---@param url string
local function open_browser(url)
  local _, err = vim.ui.open(with_theme(url))
  if err then ui.notify(err, ui.ERROR) end
end

---@param current flutter.WidgetPreviewState
---@param message string
---@param status "running"|"success"|"failed"
local function report(current, message, status)
  current.progress_id = api.nvim_echo({ { message } }, status ~= "running", {
    id = current.progress_id,
    kind = "progress",
    source = "flutter-tools",
    title = "Widget preview",
    status = status,
  })
end

---@param current flutter.WidgetPreviewState
---@param line string
local function record(current, line)
  if vim.trim(line) == "" then return end
  table.insert(current.output, line)
  if #current.output > OUTPUT_LINES_ON_FAILURE then table.remove(current.output, 1) end
end

---@param current flutter.WidgetPreviewState
---@param event {event: string, params: table?}
local function handle_event(current, event)
  local params = event.params or {}
  if event.event == "widget_preview.initializing" then
    current.pid = params.pid
  elseif event.event == "widget_preview.started" then
    current.started = true
    current.url = params.url
    if config.widget_preview.web_server then open_browser(params.url) end
    report(current, "Running at " .. params.url, "success")
  elseif event.event == "widget_preview.logMessage" then
    if params.level == "error" then
      ui.notify(params.message, ui.ERROR)
    else
      record(current, params.message)
      if params.level == "status" and not current.started then
        report(current, params.message, "running")
      end
    end
  end
end

---@param current flutter.WidgetPreviewState
---@param line string
local function handle_stdout(current, line)
  if vim.startswith(line, "[{") and vim.endswith(line, "}]") then
    local ok, events = pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
    if ok and type(events) == "table" then
      for _, event in ipairs(events) do
        if type(event) == "table" then handle_event(current, event) end
      end
      return
    end
  end
  record(current, line)
end

---@param current flutter.WidgetPreviewState
---@param on_line fun(current: flutter.WidgetPreviewState, line: string)
local function line_reader(current, on_line)
  local pending = ""
  return function(_, data)
    if not data then return end
    pending = pending .. data
    for line in pending:gmatch("([^\n]*)\n") do
      vim.schedule(function() on_line(current, line) end)
    end
    pending = pending:match("[^\n]*$")
  end
end

---@param current flutter.WidgetPreviewState
---@param dir string
---@param dtd_uri string?
local function run(current, dir, dtd_uri)
  executable.flutter(function(flutter_bin)
    if current.cancelled then return end
    local args = { flutter_bin, "widget-preview", "start", "--machine" }
    if config.widget_preview.web_server then table.insert(args, "--web-server") end
    if dtd_uri then vim.list_extend(args, { "--dtd-url", dtd_uri }) end
    local devtools_url = dev_tools.get_url()
    if devtools_url then vim.list_extend(args, { "--devtools-server-address", devtools_url }) end

    local ok, job = pcall(
      vim.system,
      args,
      {
        cwd = dir,
        stdout = line_reader(current, handle_stdout),
        stderr = line_reader(current, record),
      },
      vim.schedule_wrap(function(result)
        if state == current then state = nil end
        if current.cancelled then return report(current, "Stopped", "success") end
        if result.code == 0 then return report(current, "Exited", "success") end
        report(current, ("Exited with code %d"):format(result.code), "failed")
        ui.notify(
          vim.list_extend(
            { ("Widget preview exited with code %d"):format(result.code) },
            current.output
          ),
          ui.ERROR
        )
      end)
    )
    if not ok then
      if state == current then state = nil end
      report(current, "Failed to start", "failed")
      return ui.notify(tostring(job), ui.ERROR)
    end
    current.job = job
    report(current, "Building the preview, the first start can take a while", "running")
  end)
end

---Runs from the pub workspace root so previews from every package are included.
---@param dir string?
---@return string?
local function resolve_project_dir(dir)
  if dir and dir ~= "" then return vim.fs.normalize(vim.fn.fnamemodify(dir, ":p")) end
  local start = vim.fn.expand("%:p:h")
  return path.find_root({ "pubspec.yaml" }, start ~= "" and start or vim.fn.getcwd())
end

---@param current flutter.WidgetPreviewState
local function reveal(current)
  if not current.url then return ui.notify("Widget preview is still starting") end
  if not config.widget_preview.web_server then
    return ui.notify("The widget preview is running in the Chrome window Flutter opened")
  end
  open_browser(current.url)
end

---Starts the widget previewer, or shows the running one.
---@param dir string?
function M.show(dir)
  if vim.fn.has("nvim-0.12") == 0 then
    return ui.notify("Widget preview requires Neovim 0.12 or newer", ui.ERROR)
  end
  local project_dir = resolve_project_dir(dir)
  if state then
    if project_dir and project_dir ~= state.dir then
      return ui.notify(
        ("Widget preview is running for %s, stop it first"):format(state.dir),
        ui.WARN
      )
    end
    return reveal(state)
  end
  if not project_dir then return ui.notify("Unable to find a Flutter project", ui.ERROR) end

  ---@type flutter.WidgetPreviewState
  local current = { started = false, cancelled = false, output = {}, dir = project_dir }
  state = current
  report(current, "Starting", "running")
  dtd.start(function(err)
    if err then
      ui.notify("Unable to start the Dart Tooling Daemon: " .. err, ui.WARN)
      return run(current, project_dir, nil)
    end
    if not dtd.can_analyze(project_dir) then
      ui.notify(
        "The dart language server does not analyze "
          .. project_dir
          .. ", so the preview will not follow the editor",
        ui.WARN
      )
      return run(current, project_dir, nil)
    end
    local waiting = true
    local function run_once()
      if not waiting then return end
      waiting = false
      run(current, project_dir, dtd.uri())
    end
    vim.defer_fn(function()
      if waiting and not current.cancelled then
        ui.notify("Timed out waiting for the dart language server to analyze the project", ui.WARN)
      end
      run_once()
    end, ANALYSIS_TIMEOUT_MS)
    dtd.when_analyzed(run_once)
    if waiting then
      report(current, "Waiting for the dart language server to finish analysis", "running")
    end
  end)
end

function M.stop()
  local current = state
  if not current then return end
  current.cancelled = true
  if current.job then
    current.job:kill("sigterm")
    if current.pid then pcall(vim.uv.kill, current.pid, "sigterm") end
  else
    state = nil
    report(current, "Stopped", "success")
  end
end

---@return boolean
function M.is_running() return state ~= nil end

function M.on_exit()
  M.stop()
  dtd.stop()
end

return M
