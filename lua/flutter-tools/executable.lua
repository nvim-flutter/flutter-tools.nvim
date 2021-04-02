local utils = require("flutter-tools.utils")
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
        dart_bin = utils.join {flutter_sdk_path, "bin", "dart"},
        flutter_bin = utils.join {flutter_sdk_path, "bin", "flutter"},
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

local dart_sdk = utils.join {"cache", "dart-sdk"}

function M.dart_sdk_root_path(user_bin_path)
  if user_bin_path then
    return utils.join {user_bin_path, dart_sdk}
  end

  if utils.executable("flutter") then
    if M.paths.flutter_sdk then
      -- On Linux installations with snap the dart SDK can be further nested inside a bin directory
      -- so it's /bin/cache/dart-sdk whereas else where it is /cache/dart-sdk
      local paths = {M.paths.flutter_sdk, "cache"}
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
