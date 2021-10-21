local menu = require("flutter-tools.menu")

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

return telescope.register_extension({
  exports = {
    commands = menu.commands,
    fvm = menu.fvm,
  },
})
