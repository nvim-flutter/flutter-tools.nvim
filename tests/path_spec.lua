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
    test_dir = vim.loop.fs_realpath(temp_base)
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
