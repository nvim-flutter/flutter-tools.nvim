describe("widget guides", function()
  local config
  local guides
  local bufnr
  local api = vim.api

  local function widget(line, children)
    return {
      kind = "NEW_INSTANCE",
      range = { start = { line = line, character = 0 } },
      children = children,
    }
  end

  local function render(guides_config)
    config.set({ widget_guides = vim.tbl_extend("force", { enabled = true }, guides_config or {}) })
    guides.widget_guides(nil, {
      uri = vim.uri_from_bufnr(bufnr),
      outline = { children = { widget(0, { widget(2), widget(3) }) } },
    })
    local ns = api.nvim_get_namespaces()["flutter_tools_outline_guides"]
    local result = {}
    for _, mark in ipairs(api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })) do
      result[mark[2]] = mark[4].virt_text[1][1]
    end
    return result
  end

  before_each(function()
    package.loaded["flutter-tools.config"] = nil
    package.loaded["flutter-tools.guides"] = nil
    config = require("flutter-tools.config")
    guides = require("flutter-tools.guides")
    bufnr = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(bufnr, "/tmp/guides_spec.dart")
    api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "Column(",
      "  children: [",
      '    Text("a"),',
      '    Text("b"),',
      "  ],",
      ")",
    })
    api.nvim_set_current_buf(bufnr)
  end)

  after_each(function() api.nvim_buf_delete(bufnr, { force = true }) end)

  it("draws solid guides by default", function()
    local result = render()
    assert.are.same({ [1] = "│", [2] = "├───", [3] = "└───" }, result)
  end)

  it("uses marker overrides and falls back to the defaults", function()
    local result = render({ markers = { vertical = "┆", horizontal = "┄" } })
    assert.are.same({ [1] = "┆", [2] = "├┄┄┄", [3] = "└┄┄┄" }, result)
  end)

  it("draws nothing when disabled", function()
    local result = render({ enabled = false })
    assert.are.same({}, result)
  end)
end)
