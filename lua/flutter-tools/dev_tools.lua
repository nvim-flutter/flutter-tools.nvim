local Job = require("flutter-tools.job")
local utils = require("flutter-tools.utils")
local ui = require("flutter-tools.ui")
local executable = require("flutter-tools.executable")

local M = {}
local fn = vim.fn

local job = nil

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
local function handle_start(data)
  if data and type(data) == "table" then
    for _, str in ipairs(data) do
      if #str > 0 then
        local json = fn.json_decode(str)
        if json and json.params then
          local msg =
            string.format("Serving DevTools at http://%s:%s", json.params.host, json.params.port)
          ui.notify({msg}, 20000)
        end
      end
    end
  end
end

local function handle_error(error, data)
  ui.notify({"Sorry! devtools couldn't be opened", error, data})
  if data:match("No active package devtools") then
    return ui.notify(
      {
        "Flutter pub global devtools has not been activated.",
        "Run " .. executable.with(table.concat(activate_cmd, "")) .. " to activate it."
      }
    )
  end
end

function M.start()
  ui.notify {"Starting dev tools..."}
  if not job then
    job =
      Job:new {
      command = executable.flutter(),
      args = {"pub", "global", "run", "devtools", "--machine", "--try-ports", "10"},
      on_stderr = handle_error,
      on_exit = function(j)
        job = nil
        handle_start(j:result())
      end
    }
  else
    utils.echomsg "DevTools are already running!"
  end
end

return M
