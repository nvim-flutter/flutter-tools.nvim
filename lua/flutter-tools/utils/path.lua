-- Some path utilities, copied from nvim-lsp config
local lazy = require("flutter-tools.lazy")
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"

local luv = vim.loop
local api = vim.api
local M = {}

function M.exists(filename)
  local stat = luv.fs_stat(filename)
  return stat and stat.type or false
end

function M.is_dir(filename) return M.exists(filename) == "directory" end

function M.is_file(filename) return M.exists(filename) == "file" end

local uname = luv.os_uname()
M.is_mac = uname.sysname == "Darwin"
M.is_linux = uname.sysname == "Linux"
---@type boolean
M.is_windows = uname.version:match("Windows")
M.path_sep = M.is_windows and "\\" or "/"

local is_fs_root
if M.is_windows then
  is_fs_root = function(path) return path:match("^%a:$") end
else
  is_fs_root = function(path) return path == "/" end
end

function M.is_absolute(filename)
  if M.is_windows then
    return filename:match("^%a:") or filename:match("^\\\\")
  else
    return filename:match("^/")
  end
end

M.dirname = nil
do
  local strip_dir_pat = M.path_sep .. "([^" .. M.path_sep .. "]+)$"
  local strip_sep_pat = M.path_sep .. "$"
  M.dirname = function(path)
    if not path then return end
    local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
    if #result == 0 then return "/" end
    return result
  end
end

---Join path segments using the os separator
---@vararg string
---@return string
function M.join(...)
  local result =
    table.concat(utils.flatten({ ... }), M.path_sep):gsub(M.path_sep .. "+", M.path_sep)
  return result
end

-- Traverse the path calling cb along the way.
function M.traverse_parents(path, cb)
  path = luv.fs_realpath(path)
  local dir = path
  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    dir = M.dirname(dir)
    if not dir then return end
    -- If we can't ascend further, then stop looking.
    if cb(dir, path) then return dir, path end
    if is_fs_root(dir) then break end
  end
end

-- Iterate the path until we find the rootdir.
function M.iterate_parents(path)
  path = luv.fs_realpath(path)
  local function it(_, v)
    if not v then return end
    if is_fs_root(v) then return end
    return M.dirname(v), path
  end
  return it, path, path
end

---@param root string?
---@param path string?
function M.is_descendant(root, path)
  if not root then return false end
  if not path then return false end

  local function cb(dir, _) return dir == root end

  local dir, _ = M.traverse_parents(path, cb)

  return dir == root
end

function M.search_ancestors(startpath, func)
  if vim.fn.has("nvim-0.11") == 1 then
    vim.validate("func", func, "function")
  else
    vim.validate({ func = { func, "function" } })
  end
  if func(startpath) then return startpath end
  for path in M.iterate_parents(startpath) do
    if func(path) then return path end
  end
end

function M.find_root(patterns, startpath)
  local function matcher(path)
    for _, pattern in ipairs(patterns) do
      if M.exists(vim.fn.glob(M.join(path, pattern))) then return path end
    end
  end
  return M.search_ancestors(startpath, matcher)
end

function M.current_buffer_path()
  local current_buffer = api.nvim_get_current_buf()
  local current_buffer_path = api.nvim_buf_get_name(current_buffer)
  return current_buffer_path
end

function M.get_absolute_path(input_path)
  -- Check if the provided path is an absolute path
  if
    vim.fn.isdirectory(input_path) == 1
    and not input_path:match("^/")
    and not input_path:match("^%a:[/\\]")
  then
    -- It's a relative path, so expand it to an absolute path
    local absolute_path = vim.fn.fnamemodify(input_path, ":p")
    return absolute_path
  else
    -- It's already an absolute path
    return input_path
  end
end

function M.is_flutter_dependency_path(full_path)
  local path_parts = { [[.pub-cache]], [[Pub\Cache]], [[/fvm/versions/]] }
  if full_path then
    for _, path_part in ipairs(path_parts) do
      if full_path:find(path_part, nil, true) then return true end
    end
  end
  return false
end

return M
