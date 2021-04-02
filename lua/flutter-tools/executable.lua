local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")
local ui = require("flutter-tools.ui")

local fn = vim.fn

local M = {
  dart_bin_name = "dart"
}

local function has_shell_error()
  return vim.v.shell_error > 0 or vim.v.shell_error == -1
end

---Get paths for flutter and dart based on the binary locations
---@return string
---@return string
local function get_default_binaries()
  return fn.resolve(fn.exepath("flutter")), fn.resolve(fn.exepath("dart"))
end

---Fetch the path to the users flutter installation.
---NOTE: this should not be called before the plugin
---setup has occurred
---@return table<string, string>
local function get_paths()
  local conf = require("flutter-tools.config").get()

  if conf.flutter_path then
    return {flutter_bin = conf.flutter_path}
  end

  if conf.flutter_lookup_cmd then
    local flutter_sdk_path = utils.remove_newlines(fn.system(conf.flutter_lookup_cmd))
    if not has_shell_error() then
      return {
        dart_bin = path.join(flutter_sdk_path, "bin", "dart"),
        flutter_bin = path.join(flutter_sdk_path, "bin", "flutter"),
        flutter_sdk = flutter_sdk_path
      }
    else
      ui.notify({string.format("Error running %s", conf.flutter_lookup_cmd)})
    end
  end
  local flutter_bin, dart_bin = get_default_binaries()
  return {flutter_bin = flutter_bin, dart_bin = dart_bin}
end

M.paths = get_paths()

local dart_sdk = path.join("cache", "dart-sdk")

function M.dart_sdk_root_path(user_bin_path)
  if user_bin_path then
    return path.join(user_bin_path, dart_sdk)
  end

  if utils.executable("flutter") then
    if M.paths.flutter_sdk then
      -- On Linux installations with snap the dart SDK can be further nested inside a bin directory
      -- so it's /bin/cache/dart-sdk whereas else where it is /cache/dart-sdk
      local segments = {M.paths.flutter_sdk, "cache"}
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

---Prefix a command with the flutter executable
---@param cmd string
function M.with(cmd)
  return M.paths .. " " .. cmd
end

return M
