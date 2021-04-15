local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")
local ui = require("flutter-tools.ui")
---@type Job
local Job = require("plenary.job")

local fn = vim.fn

local M = {
  dart_bin_name = "dart",
}

---Get paths for flutter and dart based on the binary locations
---@return table<string, string>
local function get_default_binaries()
  return {
    flutter_bin = fn.resolve(fn.exepath("flutter")),
    dart_bin = fn.resolve(fn.exepath("dart")),
  }
end

---@type table<string, string>
local _paths = nil

---Execute user's lookup command and pass it to the job callback
---@param lookup_cmd string
---@param callback fun(p: string, t: table<string, string>)
---@return table<string, string>
local function path_from_lookup_cmd(lookup_cmd, callback)
  local paths = {}
  local parts = vim.split(lookup_cmd, " ")
  local cmd = parts[1]
  local args = vim.list_slice(parts, #parts)

  local job = Job:new({ command = cmd, args = args })
  job:after_failure(vim.schedule_wrap(function()
    ui.notify({ string.format("Error running %s", lookup_cmd) })
  end))
  job:after_success(vim.schedule_wrap(function(j, _)
    local result = j:result()
    local flutter_sdk_path = result[1]
    if flutter_sdk_path then
      paths.dart_bin = path.join(flutter_sdk_path, "bin", "dart")
      paths.flutter_bin = path.join(flutter_sdk_path, "bin", "flutter")
      paths.flutter_sdk = flutter_sdk_path
      callback(paths.flutter_bin, paths)
    else
      paths = get_default_binaries()
      callback(paths.flutter_bin, paths)
    end
    return paths
  end))
  job:start()
end

---Fetch the path to the users flutter installation.
---@param callback fun(paths: table<string, string>)
---@return nil
function M.get(callback)
  local conf = require("flutter-tools.config").get()
  if _paths then
    return callback(_paths.flutter_bin, _paths)
  end

  if conf.flutter_path then
    _paths = { flutter_bin = conf.flutter_path }
    return callback(_paths.flutter_bin, _paths)
  end

  if conf.flutter_lookup_cmd then
    return path_from_lookup_cmd(conf.flutter_lookup_cmd, function(p, tbl)
      _paths = tbl
      callback(p, tbl)
    end)
  end

  if not _paths then
    _paths = get_default_binaries()
  end

  return callback(_paths)
end

local dart_sdk = path.join("cache", "dart-sdk")

local function _dart_sdk_root(paths)
  if utils.executable("flutter") then
    if paths.flutter_sdk then
      -- On Linux installations with snap the dart SDK can be further nested inside a bin directory
      -- so it's /bin/cache/dart-sdk whereas else where it is /cache/dart-sdk
      local segments = { paths.flutter_sdk, "cache" }
      if not path.is_dir(path.join(unpack(segments))) then
        table.insert(segments, 2, "bin")
      end
      if path.is_dir(path.join(unpack(segments))) then
        -- remove the /cache/ directory as it's already part of the SDK path above
        segments[#segments] = nil
        return path.join(unpack(vim.tbl_flatten({ segments, dart_sdk })))
      end
    else
      local flutter_path = fn.resolve(fn.exepath("flutter"))
      local flutter_bin = fn.fnamemodify(flutter_path, ":h")
      return path.join(flutter_bin, dart_sdk)
    end
  end

  if utils.executable("dart") then
    return fn.resolve(fn.exepath("dart"))
  end

  return ""
end

--- A function to derive the sdk path for dart
---@param callback fun(cmd: string)
---@param user_bin_path string
function M.dart_sdk_root_path(callback, user_bin_path)
  assert(
    callback and type(callback) == "function",
    "A function callback must be passed in"
  )
  if user_bin_path then
    callback(path.join(user_bin_path, dart_sdk))
  end

  M.get(function(_, paths)
    vim.schedule(function()
      callback(_dart_sdk_root(paths))
    end)
  end)
end

return M
