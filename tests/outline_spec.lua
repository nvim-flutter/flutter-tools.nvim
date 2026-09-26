describe("outline", function()
  local config
  local outline
  local uri = "file:///tmp/main.dart"
  local class_icon = "\xef\x83\xa8"
  local method_icon = "\xf3\xb0\x86\xa7"

  local function node(kind, name, children)
    return {
      element = { kind = kind, name = name },
      codeRange = { start = { line = 0, character = 0 }, ["end"] = { line = 1, character = 0 } },
      children = children,
    }
  end

  local function render(outline_config)
    config.set({ outline = outline_config })
    outline.document_outline(nil, {
      uri = uri,
      outline = { children = { node("CLASS", "Foo", { node("METHOD", "bar") }) } },
    })
    return outline.outlines[uri]
  end

  before_each(function()
    package.loaded["flutter-tools.config"] = nil
    package.loaded["flutter-tools.outline"] = nil
    config = require("flutter-tools.config")
    outline = require("flutter-tools.outline")
  end)

  it("shows icons highlighted by kind by default", function()
    local result = render(nil)
    assert.are.same("  " .. class_icon .. " Foo", result[1].text)
    assert.are.same({
      value = class_icon,
      highlight = "FlutterToolsOutlineClass",
      column_start = 2,
      column_end = 2 + #class_icon,
    }, result[1].hl[1])
    assert.are.same("FlutterToolsOutlineMethod", result[2].hl[1].highlight)
  end)

  it("hides icons and their highlights when disabled", function()
    local result = render({ icons = false })
    assert.are.same("  Foo", result[1].text)
    assert.are.same("   └ bar", result[2].text)
    assert.are.same("None", result[1].hl[1].highlight)
    assert.are.same(2, result[1].hl[1].column_start)
  end)

  it("uses icon overrides and falls back to the defaults", function()
    local result = render({ icons = { CLASS = "C" } })
    assert.are.same("  C Foo", result[1].text)
    assert.are.same(4, result[1].hl[2].column_start)
    assert.are.same("   └ " .. method_icon .. " bar", result[2].text)
  end)
end)
