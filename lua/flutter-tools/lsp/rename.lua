local M = {}

local lazy = require("flutter-tools.lazy")
local lsp_utils = lazy.require("flutter-tools.lsp.utils") ---@module "flutter-tools.lsp.utils"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"

local api = vim.api
local util = vim.lsp.util
local lsp = vim.lsp
local fn = vim.fn

--- Computes a filename for a given class name (convert from PascalCase to  snake_case).
local function file_name_for_class_name(class_name)
  local starts_uppercase = class_name:find("^%u")
  if not starts_uppercase then return nil end
  local file_name = class_name:gsub("(%u)", "_%1"):lower()
  -- Removes first underscore
  file_name = file_name:sub(2)
  return file_name .. ".dart"
end

local function will_rename_files(old_name, new_name, callback)
  local params = lsp.util.make_position_params()
  if not new_name then return end
  local file_change = {
    newUri = vim.uri_from_fname(new_name),
    oldUri = vim.uri_from_fname(old_name),
  }
  params.files = { file_change }
  lsp.buf_request(0, "workspace/willRenameFiles", params, function(err, result)
    if err then
      ui.notify(err.message or "Error on getting lsp rename results!", ui.ERROR)
      return
    end
    callback(result)
  end)
end

--- Call this function when you want rename class or anything else.
--- If file will be renamed too, this function will update imports.
--- Function has same signature as `vim.lsp.buf.rename()` function and can be used instead of it.
function M.rename(new_name, options)
  options = options or {}
  local bufnr = options.bufnr or api.nvim_get_current_buf()
  local client = lsp_utils.get_dartls_client(bufnr)
  if not client then
    -- Fallback to default rename function if language server is not dartls
    return lsp.buf.rename(new_name, options)
  end

  local win = api.nvim_get_current_win()

  -- Compute early to account for cursor movements after going async
  local cword = fn.expand("<cword>")
  local actual_file_name = fn.expand("%:t")
  local old_computed_filename = file_name_for_class_name(cword)
  local is_file_rename = old_computed_filename == actual_file_name

  local function get_text_at_range(range, offset_encoding)
    return api.nvim_buf_get_text(
      bufnr,
      range.start.line,
      util._get_line_byte_from_position(bufnr, range.start, offset_encoding),
      range["end"].line,
      util._get_line_byte_from_position(bufnr, range["end"], offset_encoding),
      {}
    )[1]
  end

  local function rename(name, will_rename_files_result)
    local params = util.make_position_params(win, client.offset_encoding)
    params.newName = name
    local handler = client.handlers["textDocument/rename"] or lsp.handlers["textDocument/rename"]
    client.request("textDocument/rename", params, function(...)
      handler(...)
      if will_rename_files_result then
        -- `will_rename_files_result` contains all the places we need to update imports, so we apply those edits.
        lsp.util.apply_workspace_edit(will_rename_files_result, client.offset_encoding)
      end
    end, bufnr)
  end

  local function rename_fix_imports(name)
    if is_file_rename then
      local old_file_path = fn.expand("%:p")
      local new_filename = file_name_for_class_name(name)
      local actual_file_head = fn.expand("%:p:h")
      local new_file_path = path.join(actual_file_head, new_filename)
      will_rename_files(old_file_path, new_file_path, function(result) rename(name, result) end)
    else
      rename(name)
    end
  end

  if client.supports_method("textDocument/prepareRename") then
    local params = util.make_position_params(win, client.offset_encoding)
    client.request("textDocument/prepareRename", params, function(err, result)
      if err or result == nil then
        local msg = err and ("Error on prepareRename: " .. (err.message or ""))
          or "Nothing to rename"
        ui.notify(msg, ui.INFO)
        return
      end

      if new_name then return rename_fix_imports(new_name) end

      local prompt_opts = { prompt = "New Name: " }
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
