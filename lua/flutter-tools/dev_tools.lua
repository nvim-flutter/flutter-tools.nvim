local utils = require("flutter-tools.utils")
local ui = require("flutter-tools.ui")
local executable = require("flutter-tools.executable")
local Job = require("flutter-tools.job")

local M = {}
local fn = vim.fn

local start_id = nil

local activate_cmd = {"pub", "global", "activate", "devtools"}

--[[ {
    event = "server.started",
    method = "server.started",
    params = {
        host = "127.0.0.1",
        pid = 3407971,
        port = 9100,
        protocolVersion = "1.1.0"
    }
}]]
local function handle_start(_, data)
  if #data > 0 then
    local json = fn.json_decode(data)
    if json and json.params then
      local msg =
        string.format("Serving DevTools at http://%s:%s", json.params.host, json.params.port)
      ui.notify({msg}, 20000)
    end
  end
end

local function handle_error(_, data)
  for _, str in ipairs(data) do
    if str:match("No active package devtools") then
      executable.with(
        activate_cmd,
        function(cmd)
          ui.notify(
            {
              "Flutter pub global devtools has not been activated.",
              "Run " .. cmd .. " to activate it."
            }
          )
        end
      )
    else
      ui.notify({"Sorry! devtools couldn't be opened", unpack(data)})
    end
  end
end

function M.start()
  ui.notify {"Starting dev tools..."}
  if not start_id then
    executable.with(
      table.concat({"pub", "global", "run", "devtools", "--machine", "--try-ports", "10"}, " "),
      function(cmd)
        start_id =
          Job:new {
          cmd = cmd,
          on_stdout = handle_start,
          on_stderr = handle_error,
          on_exit = function()
            start_id = nil
            ui.notify {"Dev tools closed"}
          end
        }:start()
      end
    )
  else
    utils.echomsg "DevTools are already running!"
  end
end

return M
