local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop
local chansend = vim.fn.chansend

---@class Job
---@field id integer
---@field cmd string
---@field cwd string
---@field env table
---@field result string[]
---@field detach boolean
---@field on_stdout fun(self: Job, data: string):nil
---@field on_stderr fun(self: Job, data: string):nil
---@field on_exit fun(result: string[]):nil
local Job = {}

---Create a new Job
---@param o table
---@return Job
function Job:new(o)
  o = o or {}
  setmetatable(o, self)
  self.result = {}
  self.__index = self
  return o
end

function Job:close()
  if self.id then
    jobstop(self.id)
  end
end

---Convert the table of results into a series of calls to on
---stderr or stdout with only a single line
---@param _ integer
---@param data string[]
---@param name string
function Job:_process_result(_, data, name)
  if data and type(data) == "table" then
    vim.list_extend(self.result, data)
    for _, datum in ipairs(data) do
      if name == "stdout" and self.on_stdout then
        self:on_stdout(datum)
      elseif name == "stderr" and self.on_stderr then
        self:on_stderr(datum)
      end
    end
  end
end

function Job:send(cmd)
  if self.id then
    chansend(self.id, cmd)
  end
end

function Job:sync()
  self.id =
    jobstart(
    self.cmd,
    {
      cwd = self.cwd,
      env = self.env,
      detach = self.detach,
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(id, data, name)
        self:_process_result(id, data, name)
      end,
      on_stderr = function(id, data, name)
        self:_process_result(id, data, name)
      end,
      on_exit = function(_, code, _)
        if self.on_exit then
          self.on_exit(code ~= 0, self.result)
        end
      end
    }
  )
  return self
end

function Job:start()
  self.id =
    jobstart(
    self.cmd,
    {
      cwd = self.cwd,
      env = self.env,
      detach = self.detach,
      on_stdout = function(id, data, name)
        self:_process_result(id, data, name)
      end,
      on_stderr = function(id, data, name)
        self:_process_result(id, data, name)
      end,
      on_exit = function(_, code, _)
        if self.on_exit then
          self.on_exit(code ~= 0, self.result)
        end
      end
    }
  )
  return self
end

return Job
