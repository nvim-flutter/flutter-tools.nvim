local path = require("flutter-tools.utils.path")

describe("path.find_root", function()
  local test_dir
  local workspace_root
  local package_a
  local package_b
  local standalone

  before_each(function()
    -- Use realpath to normalize (handles /var -> /private/var symlink on macOS)
    local temp_base = vim.fn.tempname()
    vim.fn.mkdir(temp_base, "p")
    test_dir = vim.uv.fs_realpath(temp_base)
    workspace_root = test_dir .. "/workspace"
    package_a = workspace_root .. "/packages/package_a"
    package_b = workspace_root .. "/packages/package_b"
    standalone = test_dir .. "/standalone"

    vim.fn.mkdir(package_a, "p")
    vim.fn.mkdir(package_b, "p")
    vim.fn.mkdir(standalone, "p")

    vim.fn.writefile({
      "name: my_workspace",
      "workspace:",
      "  - packages/package_a",
      "  - packages/package_b",
    }, workspace_root .. "/pubspec.yaml")

    vim.fn.writefile({
      "name: package_a",
      "resolution: workspace",
    }, package_a .. "/pubspec.yaml")

    vim.fn.writefile({
      "name: package_b",
      "resolution: workspace",
    }, package_b .. "/pubspec.yaml")

    vim.fn.writefile({
      "name: standalone",
      "version: 1.0.0",
    }, standalone .. "/pubspec.yaml")
  end)

  after_each(function() vim.fn.delete(test_dir, "rf") end)

  local patterns = { "pubspec.yaml" }

  it("should find workspace root from member package", function()
    local file_path = package_a .. "/lib/main.dart"
    vim.fn.mkdir(package_a .. "/lib", "p")
    vim.fn.writefile({ "void main() {}" }, file_path)

    assert.are.equal(workspace_root, path.find_root(patterns, file_path))
  end)

  it("should find workspace root from nested directory", function()
    local nested_dir = package_b .. "/lib/src/widgets"
    vim.fn.mkdir(nested_dir, "p")
    local file_path = nested_dir .. "/button.dart"
    vim.fn.writefile({ "class Button {}" }, file_path)

    assert.are.equal(workspace_root, path.find_root(patterns, file_path))
  end)

  it("should return package root for non-workspace package", function()
    local file_path = standalone .. "/lib/main.dart"
    vim.fn.mkdir(standalone .. "/lib", "p")
    vim.fn.writefile({ "void main() {}" }, file_path)

    assert.are.equal(standalone, path.find_root(patterns, file_path))
  end)

  it("should return workspace root when starting from workspace root", function()
    local file_path = workspace_root .. "/tool/script.dart"
    vim.fn.mkdir(workspace_root .. "/tool", "p")
    vim.fn.writefile({ "void main() {}" }, file_path)

    assert.are.equal(workspace_root, path.find_root(patterns, file_path))
  end)
end)

describe("path.pub_cache_dir", function()
  local original_pub_cache
  local original_home

  before_each(function()
    original_pub_cache = vim.env.PUB_CACHE
    original_home = vim.env.HOME
  end)

  after_each(function()
    vim.env.PUB_CACHE = original_pub_cache
    vim.env.HOME = original_home
  end)

  it("should use PUB_CACHE when it is set", function()
    vim.env.PUB_CACHE = "/custom/pub-cache"
    assert.are.equal("/custom/pub-cache", path.pub_cache_dir())
  end)

  it("should fall back to the default location when PUB_CACHE is unset", function()
    vim.env.PUB_CACHE = nil
    vim.env.HOME = "/home/user"
    local expected = path.is_windows and path.join(vim.env.LOCALAPPDATA, "Pub", "Cache")
      or "/home/user/.pub-cache"
    assert.are.equal(expected, path.pub_cache_dir())
  end)
end)

describe("path.is_flutter_dependency_path", function()
  local test_dir
  local sdk
  local project

  before_each(function()
    local temp_base = vim.fn.tempname()
    vim.fn.mkdir(temp_base, "p")
    test_dir = vim.uv.fs_realpath(temp_base)
    sdk = test_dir .. "/mise/installs/flutter/3.47.1"
    project = test_dir .. "/my_app"

    vim.fn.mkdir(sdk .. "/bin/cache/dart-sdk", "p")
    vim.fn.writefile({}, sdk .. "/bin/flutter")
    vim.fn.mkdir(sdk .. "/packages/flutter/lib/src/widgets", "p")
    vim.fn.mkdir(project .. "/lib", "p")
  end)

  after_each(function() vim.fn.delete(test_dir, "rf") end)

  it("should detect files inside a Flutter SDK installed anywhere", function()
    local file_path = sdk .. "/packages/flutter/lib/src/widgets/basic.dart"
    assert.is_true(path.is_flutter_dependency_path(file_path))
  end)

  it("should not detect a directory without a Dart SDK as a Flutter SDK", function()
    vim.fn.delete(sdk .. "/bin/cache", "rf")
    local file_path = sdk .. "/packages/flutter/lib/src/widgets/basic.dart"
    assert.is_false(path.is_flutter_dependency_path(file_path))
  end)

  it(
    "should not detect project files",
    function() assert.is_false(path.is_flutter_dependency_path(project .. "/lib/main.dart")) end
  )

  it("should detect pub cache files", function()
    local file_path = "/home/user/.pub-cache/hosted/pub.dev/http-1.2.0/lib/http.dart"
    assert.is_true(path.is_flutter_dependency_path(file_path))
  end)

  it("should handle missing paths", function()
    assert.is_false(path.is_flutter_dependency_path(nil))
    assert.is_false(path.is_flutter_dependency_path(""))
  end)
end)

describe("path.is_home_or_fs_root", function()
  it(
    "should reject the home directory",
    function() assert.is_true(path.is_home_or_fs_root(vim.uv.os_homedir())) end
  )

  it("should reject the filesystem root", function()
    local fs_root = path.is_windows and "C:\\" or "/"
    assert.is_true(path.is_home_or_fs_root(fs_root))
  end)

  it("should accept a project directory", function()
    local project = vim.fn.tempname()
    vim.fn.mkdir(project, "p")
    assert.is_false(path.is_home_or_fs_root(project))
    vim.fn.delete(project, "rf")
  end)
end)
