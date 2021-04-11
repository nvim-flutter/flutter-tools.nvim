local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")
local ui = require("flutter-tools.ui")
local Job = require("flutter-tools.job")

local fn = vim.fn

local M = {
  dart_bin_name = "dart"
}

---Get paths for flutter and dart based on the binary locations
---@return string
---@return string
local function get_default_binaries()
  return {
    flutter_bin = fn.resolve(fn.exepath("flutter")),
    dart_bin = fn.resolve(fn.exepath("dart"))
  }
end

local _paths = nil
---Fetch the path to the users flutter installation.
---@param callback fun(paths: table<string, string>)
---@return nil
function M.derive_paths(callback)
  local conf = require("flutter-tools.config").get()
  if _paths then
    return callback(_paths)
  end

  if conf.flutter_path then
    _paths = {flutter_bin = conf.flutter_path}
    return callback(_paths)
  end

  if conf.flutter_lookup_cmd then
    Job:new {
      cmd = conf.flutter_lookup_cmd,
      on_stderr = function()
        ui.notify({string.format("Error running %s", conf.flutter_lookup_cmd)})
      end,
      on_exit = function(_, result)
        local res = result[1]
        if res then
          local flutter_sdk_path = utils.remove_newlines(res)
          _paths = {
            dart_bin = path.join(flutter_sdk_path, "bin", "dart"),
            flutter_bin = path.join(flutter_sdk_path, "bin", "flutter"),
            flutter_sdk = flutter_sdk_path
          }
          return callback(_paths)
        else
          _paths = get_default_binaries()
          return callback(_paths)
        end
      end
    }:sync()
  else
    _paths = get_default_binaries()
    return callback(_paths)
  end
end

local dart_sdk = path.join("cache", "dart-sdk")

local function _dart_sdk_root(paths)
  if utils.executable("flutter") then
    if paths.flutter_sdk then
      -- On Linux installations with snap the dart SDK can be further nested inside a bin directory
      -- so it's /bin/cache/dart-sdk whereas else where it is /cache/dart-sdk
      local segments = {paths.flutter_sdk, "cache"}
      if not path.is_dir(path.join(unpack(segments))) then
        table.insert(segments, 2, "bin")
      end
      if path.is_dir(path.join(unpack(segments))) then
        -- remove the /cache/ directory as it's already part of the SDK path above
        segments[#segments] = nil
        return path.join(unpack(vim.tbl_flatten {segments, dart_sdk}))
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
---@param callback fun(path: string)
---@param user_bin_path string
function M.dart_sdk_root_path(callback, user_bin_path)
  assert(callback and type(callback) == "function", "A function callback must be passed in")
  if user_bin_path then
    callback(path.join(user_bin_path, dart_sdk))
  end

  M.derive_paths(
    function(paths)
      callback(_dart_sdk_root(paths))
    end
  )
end

---Prefix a command with the flutter executable
---@param cmd string
function M.with(cmd, callback)
  assert(callback and type(callback) == "function", "A function callback must be passed in")
  M.derive_paths(
    function(paths)
      callback(paths.flutter_bin .. " " .. cmd)
    end
  )
end

return M
