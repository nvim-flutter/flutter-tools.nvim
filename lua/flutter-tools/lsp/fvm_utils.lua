local M = {}

local lazy = require("flutter-tools.lazy")

local fn = vim.fn
local luv = vim.loop

local lsp_utils = lazy.require("flutter-tools.lsp.utils") ---@module "flutter-tools.lsp.utils"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local config_utils = lazy.require("flutter-tools.utils.config_utils") ---@module "flutter-tools.utils.config_utils"


--- Gets the FVM root directory by traversing upwards
--- @returns string?
function M.find_fvm_root()
  local current_path = path.current_buffer_path();
  local search_path = lsp_utils.is_valid_path(current_path) and current_path or config_utils.get_cwd()
  return search_path and path.find_root({ ".fvm" }, search_path)
end

--- Gets the flutter binary from fvm root folder
--- @param fvm_root string fvm root folder
--- @return string?
function M.flutter_bin_from_fvm(fvm_root)
  local binary_name = path.is_windows and "flutter.bat" or "flutter"
  local flutter_bin_symlink = path.join(fvm_root, ".fvm", "flutter_sdk", "bin", binary_name)
  flutter_bin_symlink = fn.exepath(flutter_bin_symlink)
  local flutter_bin = luv.fs_realpath(flutter_bin_symlink)
  if path.exists(flutter_bin_symlink) and path.exists(flutter_bin) then return flutter_bin end
end

return M
