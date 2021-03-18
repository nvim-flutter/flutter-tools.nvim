local config = require("flutter-tools.config")
local utils = require("flutter-tools.utils")
local ui = require("flutter-tools.ui")

local fn = vim.fn

local M = {
  dart_bin_name = "dart",
  dart_bin_path = nil,
  flutter_bin_path = nil,
  flutter_sdk_path = nil
}

local dart_sdk = utils.join {"cache", "dart-sdk"}

function M.dart_sdk_root_path(user_bin_path)
  if user_bin_path then
    return utils.join {user_bin_path, dart_sdk}
  elseif utils.executable("flutter") then
    local _, flutter_sdk = M.get_flutter()
    if flutter_sdk then
      -- On Linux installations with snap the dart SDK can be further nested inside a bin directory
      -- so it's /bin/cache/dart-sdk whereas else where it is /cache/dart-sdk
      local paths = {flutter_sdk, "cache"}
      if not utils.is_dir(utils.join(paths)) then
        table.insert(paths, 2, "bin")
      end
      if utils.is_dir(utils.join(paths)) then
        -- remove the /cache/ directory as it's already part of the SDK path above
        paths[#paths] = nil
        return utils.join(vim.tbl_flatten {paths, dart_sdk})
      end
    else
      local flutter_path = fn.resolve(fn.exepath("flutter"))
      local flutter_bin = fn.fnamemodify(flutter_path, ":h")
      return utils.join {flutter_bin, dart_sdk}
    end
  elseif utils.executable("dart") then
    return fn.resolve(fn.exepath("dart"))
  else
    return ""
  end
end

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
---@return string
function M.get_flutter()
  if M.flutter_bin_path then
    return M.flutter_bin_path
  end

  local _config = config.get()
  if _config.flutter_path then
    M.flutter_bin_path = _config.flutter_path
  elseif _config.flutter_lookup_cmd then
    M.flutter_sdk_path = utils.remove_newlines(fn.system(_config.flutter_lookup_cmd))

    if not has_shell_error() then
      M.dart_bin_path = utils.join {M.flutter_sdk_path, "bin", "dart"}
      M.flutter_bin_path = utils.join {M.flutter_sdk_path, "bin", "flutter"}
    else
      ui.notify({string.format("Error running %s", _config.flutter_lookup_cmd)})
      M.flutter_bin_path, M.dart_bin_path = get_default_binaries()
    end
  else
    M.flutter_bin_path, M.dart_bin_path = get_default_binaries()
  end

  return M.flutter_bin_path, M.flutter_sdk_path
end

---Prefix a command with the flutter executable
---@param cmd string
function M.with(cmd)
  return M.get_flutter() .. " " .. cmd
end

return M
