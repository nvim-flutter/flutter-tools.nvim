local success, Job = pcall(require, "plenary.job")

if not success then
  require("flutter-tools.utils").echomsg(
    "Plenary is required to use Flutter tools please ensure it is installed",
    "ErrorMsg"
  )
end

return Job
