local M = {}

local lazy = require("flutter-tools.lazy")
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local lsp = lazy.require("flutter-tools.lsp") ---@module "flutter-tools.utils"

--- Gets the appropriate cwd
---@param project_conf flutter.ProjectConfig?
---@returns string?
function M.get_cwd(project_conf)
  if project_conf and project_conf.cwd then
    local resolved_path = path.get_absolute_path(project_conf.cwd)
    if not vim.loop.fs_stat(resolved_path) then
      return ui.notify("Provided cwd does not exist: " .. resolved_path, ui.ERROR)
    end
    return resolved_path
  end
  return lsp.get_project_root_dir()
end

return M
