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
---@field private __process_result fun(id: integer, data: string[], name: string): table
---@field private __make_args fun(overrides: table): table
---@field private __is_alive fun(): boolean
---@field private __set_status fun(status: integer): nil
local Job = {}

local status = {
  ALIVE = 0,
  DEAD = 1
}

function Job:__make_args(overrides)
  return {
    cwd = overrides.cwd or self.cwd,
    env = overrides.env or self.env,
    detach = overrides.detach or self.detach,
    stdout_buffered = overrides.stdout_buffered,
    stderr_buffered = overrides.stderr_buffered,
    on_stdout = function(id, data, name)
      self:__process_result(id, data, name)
    end,
    on_stderr = function(id, data, name)
      self:__process_result(id, data, name)
    end,
    on_exit = function(_, code, _)
      if self.on_exit then
        self.on_exit(code ~= 0, self.result)
        self:__set_status(status.DEAD)
      end
    end
  }
end

---Create a new Job
---@param o table
---@return Job
function Job:new(o)
  o = o or {}
  setmetatable(o, self)
  self.result = {""}
  self:__set_status(status.ALIVE)
  self.__index = self
  return o
end

function Job:__is_alive()
  return self.status ~= status.DEAD
end

---Set the state of a Job
function Job:__set_status(s)
  self.status = s
end

function Job:close()
  if self.id and self:__is_alive() then
    jobstop(self.id)
    self:__set_status(status.DEAD)
  end
end

---Convert the table of results into a series of calls to on
---stderr or stdout with only a single line
function Job:__process_result(_, data, name)
  if data and type(data) == "table" then
    if data[#data] == "" then
      data[#data] = nil
    end
    if data[1] then
      self.result[#self.result] = self.result[#self.result] .. data[1]
    end
    vim.list_extend(self.result, vim.list_slice(data, 2, #data))
    for _, datum in ipairs(data) do
      if datum then
        if name == "stdout" and self.on_stdout then
          self:on_stdout(datum)
        elseif name == "stderr" and self.on_stderr then
          self:on_stderr(datum)
        end
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
  self.id = jobstart(self.cmd, self:__make_args({stdout_buffered = true, stderr_buffered = true}))
  return self
end

function Job:start()
  self.id = jobstart(self.cmd, self:__make_args(self))
  return self
end

return Job
