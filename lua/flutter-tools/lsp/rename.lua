---@diagnostic disable: invisible
local M = {}

local lazy = require("flutter-tools.lazy")
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local lsp_utils = lazy.require("flutter-tools.lsp.utils") ---@module "flutter-tools.lsp.utils"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"

local api = vim.api
local util = vim.lsp.util
local lsp = vim.lsp
local fn = vim.fn
local fs = vim.fs

--- Computes a filename for a given class name (convert from PascalCase to  snake_case).
---@param class_name string
---@return string?
local function convert_to_file_name(class_name)
  local starts_uppercase = class_name:find("^%u")
  if not starts_uppercase then return end
  local file_name = class_name:gsub("(%u)", "_%1"):lower()
  -- Removes first underscore
  file_name = file_name:sub(2)
  return file_name .. ".dart"
end

--- Call this function when you want rename class or anything else.
--- If file will be renamed too, this function will update imports.
--- This is a modified version of `vim.lsp.buf.rename()` function and can be used instead of it.
--- Original version: https://github.com/neovim/neovim/blob/release-0.11/runtime/lua/vim/lsp/buf.lua#L640
function M.rename(new_name, opts)
  opts = opts or {}
  local bufnr = vim._resolve_bufnr(opts.bufnr)
  local client = lsp_utils.get_dartls_client(bufnr)
  if not client or config.lsp.settings.renameFilesWithClasses ~= "always" then
    -- Fallback to default rename function if language server is not dartls
    -- or if user doesn't want to rename files on class rename.
    return lsp.buf.rename(new_name, opts)
  end

  local win = api.nvim_get_current_win()

  -- Compute early to account for cursor movements after going async
  local cword = fn.expand("<cword>")
  local current_file_path = api.nvim_buf_get_name(bufnr)
  local current_file_name = fs.basename(current_file_path)
  local filename_from_class_name = convert_to_file_name(cword)
  local is_file_rename = filename_from_class_name == current_file_name

  ---@param range lsp.Range
  ---@param position_encoding string
  local function get_text_at_range(range, position_encoding)
    return api.nvim_buf_get_text(
      bufnr,
      range.start.line,
      util._get_line_byte_from_position(bufnr, range.start, position_encoding),
      range["end"].line,
      util._get_line_byte_from_position(bufnr, range["end"], position_encoding),
      {}
    )[1]
  end

  ---@param name string the name of the thing
  ---@param result table|nil the result from the call to will rename
  local function rename(name, result)
    local params = util.make_position_params(win, client.offset_encoding) --[[@as lsp.RenameParams]]
    params.newName = name
    local handler = client.handlers["textDocument/rename"] or lsp.handlers["textDocument/rename"]
    client.request("textDocument/rename", params, function(...)
      handler(...)
      if result then lsp.util.apply_workspace_edit(result, client.offset_encoding) end

      -- Save all modified buffers after applying workspace edits
      vim.cmd("silent! wa")
    end, bufnr)
  end

  ---@param name string
  local function rename_fix_imports(name)
    if is_file_rename then
      local new_filename = convert_to_file_name(name)
      local new_file_path = path.join(fs.dirname(current_file_path), new_filename)

      -- Create a custom params object for willRenameFiles request
      ---@class WillRenameFilesParams
      local params = {
        files = {
          {
            oldUri = vim.uri_from_fname(current_file_path),
            newUri = vim.uri_from_fname(new_file_path),
          },
        },
      }

      client.request("workspace/willRenameFiles", params, function(err, result)
        if err then
          ui.notify(err.message or "Error on getting lsp rename results!", ui.ERROR)
          return
        end
        rename(name, result)
      end, bufnr)
    else
      rename(name)
    end
  end

  -- Try to use prepare rename first
  if client.supports_method("textDocument/prepareRename") then
    local params = util.make_position_params(win, client.offset_encoding)
    client.request("textDocument/prepareRename", params, function(err, result)
      if err or result == nil then
        if err then
          ui.notify(("Error on prepareRename: %s"):format(err.message), ui.ERROR)
        else
          ui.notify("Nothing to rename", ui.INFO)
        end
        return
      end

      if new_name then
        rename_fix_imports(new_name)
        return
      end

      local prompt_opts = {
        prompt = "New Name: ",
      }
      -- result: Range | { range: Range, placeholder: string }
      if result.placeholder then
        prompt_opts.default = result.placeholder
      elseif result.start then
        prompt_opts.default = get_text_at_range(result, client.offset_encoding)
      elseif result.range then
        prompt_opts.default = get_text_at_range(result.range, client.offset_encoding)
      else
        prompt_opts.default = cword
      end
      ui.input(prompt_opts, function(input)
        if not input or #input == 0 then return end
        rename_fix_imports(input)
      end)
    end, bufnr)
  else
    assert(client.supports_method("textDocument/rename"), "Client must support textDocument/rename")
    if new_name then
      rename_fix_imports(new_name)
      return
    end

    local prompt_opts = {
      prompt = "New Name: ",
      default = cword,
    }
    ui.input(prompt_opts, function(input)
      if not input or #input == 0 then return end
      rename_fix_imports(input)
    end)
  end
end

return M
