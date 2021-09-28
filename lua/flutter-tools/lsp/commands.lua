local M = {}

function M.refactor_perform(command, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local prompt
  local kind = command.arguments[1]
  if kind == "EXTRACT_METHOD" then
    prompt = "Enter a name for the method: "
  elseif kind == "EXTRACT_WIDGET" then
    prompt = "Enter a name for the widget: "
  elseif kind == "EXTRACT_LOCAL_VARIABLE" then
    prompt = "Enter a name for the variable: "
  else
    client.request("workspace/executeCommand", command)
    return
  end

  local optionsIndex = 6
  local name = vim.fn.input(prompt)
  command.arguments[optionsIndex] = {
    name = name,
  }

  client.request("workspace/executeCommand", command)
end

return M
