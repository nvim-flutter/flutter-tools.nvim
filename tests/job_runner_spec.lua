describe("job runner", function()
  local runner

  before_each(function() runner = require("flutter-tools.runners.job_runner") end)

  after_each(function()
    runner:cleanup()
    package.loaded["flutter-tools.runners.job_runner"] = nil
  end)

  ---@param project_config flutter.ProjectConfig?
  ---@return string[]
  local function run_and_collect_output(project_config)
    local output, exited = {}, false
    runner:run(
      {},
      { flutter_bin = "sh" },
      { "-c", 'echo "$FLUTTER_TOOLS_SPEC_VAR|$HOME"' },
      vim.uv.cwd(),
      function(_, line) table.insert(output, line) end,
      function() exited = true end,
      true,
      project_config
    )
    vim.wait(5000, function() return exited end)
    return output
  end

  it("adds the project configuration env to the inherited environment", function()
    local output = run_and_collect_output({ env = { FLUTTER_TOOLS_SPEC_VAR = "dev" } })

    assert.are.same({ "dev|" .. vim.env.HOME }, output)
  end)

  it("inherits the environment unchanged without a project configuration env", function()
    local output = run_and_collect_output({})

    assert.are.same({ "|" .. vim.env.HOME }, output)
  end)
end)
