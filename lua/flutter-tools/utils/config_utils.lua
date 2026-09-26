local M = {}

local lazy = require("flutter-tools.lazy")
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local lsp = lazy.require("flutter-tools.lsp") ---@module "flutter-tools.utils"
local parser = lazy.require("flutter-tools.utils.yaml_parser")

--- Gets the appropriate cwd
---@param project_conf flutter.ProjectConfig?
---@returns string?
function M.get_cwd(project_conf)
  if project_conf and project_conf.cwd then
    local resolved_path = path.get_absolute_path(project_conf.cwd)
    if not vim.uv.fs_stat(resolved_path) then
      return ui.notify("Provided cwd does not exist: " .. resolved_path, ui.ERROR)
    end
    return resolved_path
  end
  return lsp.get_project_root_dir()
end

--@return table?
local function parse_yaml(str)
  local ok, yaml = pcall(parser.parse, str)
  if not ok then return nil end
  return yaml
end

---@param cwd string
function M.has_flutter_dependency_in_pubspec(cwd)
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

return M
