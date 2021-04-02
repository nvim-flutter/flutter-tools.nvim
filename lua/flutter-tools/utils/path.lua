local luv = vim.loop

-- Some path utilities
local function exists(filename)
  local stat = luv.fs_stat(filename)
  return stat and stat.type or false
end

local function is_dir(filename)
  return exists(filename) == "directory"
end

local function is_file(filename)
  return exists(filename) == "file"
end

local is_linux = luv.os_uname().sysname == "Linux"
local is_windows = luv.os_uname().version:match("Windows")
local path_sep = is_windows and "\\" or "/"

local is_fs_root
if is_windows then
  is_fs_root = function(path)
    return path:match("^%a:$")
  end
else
  is_fs_root = function(path)
    return path == "/"
  end
end

local function is_absolute(filename)
  if is_windows then
    return filename:match("^%a:") or filename:match("^\\\\")
  else
    return filename:match("^/")
  end
end

local dirname
do
  local strip_dir_pat = path_sep .. "([^" .. path_sep .. "]+)$"
  local strip_sep_pat = path_sep .. "$"
  dirname = function(path)
    if not path then
      return
    end
    local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
    if #result == 0 then
      return "/"
    end
    return result
  end
end

local function path_join(...)
  local result = table.concat(vim.tbl_flatten {...}, path_sep):gsub(path_sep .. "+", path_sep)
  return result
end

-- Traverse the path calling cb along the way.
local function traverse_parents(path, cb)
  path = luv.fs_realpath(path)
  local dir = path
  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    dir = dirname(dir)
    if not dir then
      return
    end
    -- If we can't ascend further, then stop looking.
    if cb(dir, path) then
      return dir, path
    end
    if is_fs_root(dir) then
      break
    end
  end
end

-- Iterate the path until we find the rootdir.
local function iterate_parents(path)
  path = luv.fs_realpath(path)
  local function it(_, v)
    if not v then
      return
    end
    if is_fs_root(v) then
      return
    end
    return dirname(v), path
  end
  return it, path, path
end

local function is_descendant(root, path)
  if (not path) then
    return false
  end

  local function cb(dir, _)
    return dir == root
  end

  local dir, _ = traverse_parents(path, cb)

  return dir == root
end

return {
  is_dir = is_dir,
  is_file = is_file,
  is_absolute = is_absolute,
  exists = exists,
  sep = path_sep,
  dirname = dirname,
  join = path_join,
  traverse_parents = traverse_parents,
  iterate_parents = iterate_parents,
  is_descendant = is_descendant,
  is_windows = is_windows,
  is_linux = is_linux,
}
