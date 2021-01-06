local utils = require "flutter-tools/utils"
local ui = require "flutter-tools/ui"
local M = {}
local fn = vim.fn

local start_id = nil

local activate_cmd = {"flutter", "pub", "global", "activate", "devtools"}

local function handle_start(_, data, name)
  if data then
    for _, str in ipairs(data) do
      if #str > 0 then
        if name == "stderr" then
          if str:match("No active package devtools") then
            ui.notify(
              {
                "Flutter pub global devtools has not been activated.",
                "Run " .. table.concat(activate_cmd, "").. " to activate it."
              }
            )
          end
        else
          local json = fn.json_decode(str)
          if json and json.params then
            -- {
            --   event = "server.started",
            --   method = "server.started",
            --   params = {
            --     host = "127.0.0.1",
            --     pid = 3407971,
            --     port = 9100,
            --     protocolVersion = "1.1.0"
            --   }
            -- }
            local msg =
              string.format("Serving DevTools at http://%s:%s", json.params.host, json.params.port)
            ui.notify({msg}, 20000)
          end
        end
      end
    end
  end
end

function M.start()
  ui.notify {"Starting dev tools..."}
  if not start_id then
    start_id =
      fn.jobstart(
      table.concat(
        {
          "flutter",
          "pub",
          "global",
          "run",
          "devtools",
          "--machine",
          "--try-ports",
          "10"
        },
        " "
      ),
      {
        on_stdout = handle_start,
        on_stderr = handle_start,
        on_exit = function(...)
          start_id = nil
          handle_start(...)
        end
      }
    )
  else
    utils.echomsg "DevTools are already running!"
  end
end

return M
