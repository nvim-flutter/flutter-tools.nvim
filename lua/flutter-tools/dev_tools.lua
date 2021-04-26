local utils = require("flutter-tools.utils")
local ui = require("flutter-tools.ui")
local executable = require("flutter-tools.executable")
---@type Job
local Job = require("plenary.job")

local M = {}
local fn = vim.fn

---@type Job
local job = nil

local activate_cmd = { "pub", "global", "activate", "devtools" }

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
---Open dev tools
---@param _ number
---@param data string
---@param __ Job
local function handle_start(_, data, __)
  if #data > 0 then
    local json = fn.json_decode(data)
    if json and json.params then
      local msg =
        string.format("Serving DevTools at http://%s:%s", json.params.host, json.params.port)
      ui.notify({ msg }, 20000)
    end
  end
end

---Handler errors whilst opening dev tools
---@param _ number
---@param data string
---@param __ Job
local function handle_error(_, data, __)
  for _, str in ipairs(data) do
    if str:match("No active package devtools") then
      executable.get(function(cmd)
        ui.notify({
          "Flutter pub global devtools has not been activated.",
          "Run " .. cmd .. table.concat(activate_cmd, " ") .. " to activate it.",
        })
      end)
    else
      ui.notify({ "Sorry! devtools couldn't be opened", unpack(data) })
    end
  end
end

function M.start()
  ui.notify({ "Starting dev tools..." })
  if not job then
    executable.get(function(cmd)
      job = Job:new({
        command = cmd,
        args = {
          "pub",
          "global",
          "run",
          "devtools",
          "--machine",
          "--try-ports",
          "10",
        },
        on_stdout = vim.schedule_wrap(handle_start),
        on_stderr = vim.schedule_wrap(handle_error),
        on_exit = vim.schedule_wrap(function()
          job = nil
          ui.notify({ "Dev tools closed" })
        end),
      })

      job:start()
    end)
  else
    utils.echomsg("DevTools are already running!")
  end
end

return M
